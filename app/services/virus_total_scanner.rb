require "net/http"
require "json"

class VirusTotalScanner
  API_KEY = ENV["VIRUSTOTAL_API_KEY"].to_s
  BASE     = "https://www.virustotal.com/api/v3"

  class Error < StandardError; end

  def self.scan(attachment)
    new(attachment).scan
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def scan
    return skip!("No API key configured")           if API_KEY.blank?
    return skip!("Content type not scannable")      unless @attachment.vt_scannable?
    return skip!("File too large for VT free tier") if @attachment.byte_size > 32.megabytes

    @attachment.update_columns(vt_status: "scanning")

    url_id = submit_url
    if url_id
      poll_and_update(url_id)
    else
      file_id = submit_file
      poll_and_update(file_id) if file_id
    end
  rescue => e
    Rails.logger.error("VirusTotalScanner error attachment=#{@attachment.id}: #{e.message}")
    @attachment.update_columns(vt_status: "skipped")
  end

  private

  def submit_url
    return nil unless @attachment.file.attached?

    download_url = Rails.application.routes.url_helpers.rails_blob_url(
      @attachment.file.blob,
      host: ENV.fetch("APP_HOST", "unknownforums.fun")
    )

    res = post_json("#{BASE}/urls", { url: download_url })
    res.dig("data", "id")
  rescue
    nil
  end

  def submit_file
    blob = @attachment.file.blob
    file_data = blob.download

    uri  = URI("#{BASE}/files")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req["x-apikey"] = API_KEY
    req["accept"]   = "application/json"

    boundary = "VTBoundary#{SecureRandom.hex(8)}"
    req["content-type"] = "multipart/form-data; boundary=#{boundary}"
    req.body = [
      "--#{boundary}\r\n",
      "Content-Disposition: form-data; name=\"file\"; filename=\"#{@attachment.filename}\"\r\n",
      "Content-Type: #{@attachment.content_type}\r\n\r\n",
      file_data,
      "\r\n--#{boundary}--\r\n"
    ].join

    body = JSON.parse(http.request(req).body)
    body.dig("data", "id")
  rescue => e
    Rails.logger.error("VT file submit failed: #{e.message}")
    nil
  end

  def poll_and_update(analysis_id)
    @attachment.update_columns(vt_scan_id: analysis_id)

    5.times do |i|
      sleep(i * 5 + 5)
      res  = get_json("#{BASE}/analyses/#{analysis_id}")
      stat = res.dig("data", "attributes", "status")
      next unless stat == "completed"

      stats  = res.dig("data", "attributes", "stats") || {}
      result = classify(stats)
      @attachment.update_columns(
        vt_status:    result,
        vt_report:    stats,
        vt_scanned_at: Time.current
      )
      return
    end

    @attachment.update_columns(vt_status: "skipped")
  end

  def classify(stats)
    malicious   = stats["malicious"].to_i
    suspicious  = stats["suspicious"].to_i
    if malicious >= 3
      "malicious"
    elsif malicious >= 1 || suspicious >= 3
      "suspicious"
    else
      "clean"
    end
  end

  def post_json(url, payload)
    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req  = Net::HTTP::Post.new(uri)
    req["x-apikey"]    = API_KEY
    req["accept"]      = "application/json"
    req["content-type"] = "application/x-www-form-urlencoded"
    req.body = URI.encode_www_form(payload)
    JSON.parse(http.request(req).body)
  end

  def get_json(url)
    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req  = Net::HTTP::Get.new(uri)
    req["x-apikey"] = API_KEY
    req["accept"]   = "application/json"
    JSON.parse(http.request(req).body)
  end

  def skip!(reason)
    Rails.logger.info("VT scan skipped attachment=#{@attachment.id}: #{reason}")
    @attachment.update_columns(vt_status: "skipped")
  end
end
