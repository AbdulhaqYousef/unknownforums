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
    return skip!("No API key configured") unless API_KEY.present?
    return skip!("File is not attached") unless @attachment.vt_scannable?

    @attachment.update_columns(vt_status: "scanning")

    return poll_and_update(@attachment.vt_scan_id) if @attachment.vt_scan_id.present?

    file_id = submit_file
    return poll_and_update(file_id) if file_id

    url_id = submit_url
    return poll_and_update(url_id) if url_id

    skip!("VirusTotal did not accept file or URL submission")
  rescue => e
    Rails.logger.error("VirusTotalScanner error attachment=#{@attachment.id}: #{e.message}")
    return retry_later! if @attachment.vt_scan_id.present?

    @attachment.update_columns(vt_status: "skipped")
    :skipped
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

    uri  = URI(file_upload_url)
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

    response = http.request(req)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("VT file submit failed attachment=#{@attachment.id}: HTTP #{response.code} #{response.body}")
      return nil
    end

    body = JSON.parse(response.body)
    body.dig("data", "id")
  rescue => e
    Rails.logger.error("VT file submit failed: #{e.message}")
    nil
  end

  def file_upload_url
    return "#{BASE}/files" if @attachment.byte_size.to_i <= 32.megabytes

    get_json("#{BASE}/files/upload_url").fetch("data")
  rescue => e
    Rails.logger.error("VT large-file upload URL failed: #{e.message}")
    "#{BASE}/files"
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
        approved:     result == "clean" ? true : @attachment.approved?,
        vt_report:    stats,
        vt_scanned_at: Time.current
      )
      return :completed
    end

    @attachment.update_columns(vt_status: "scanning")
    :pending
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
    response = http.request(req)
    raise Error, "HTTP #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def get_json(url)
    uri  = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req  = Net::HTTP::Get.new(uri)
    req["x-apikey"] = API_KEY
    req["accept"]   = "application/json"
    response = http.request(req)
    raise Error, "HTTP #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def skip!(reason)
    Rails.logger.info("VT scan skipped attachment=#{@attachment.id}: #{reason}")
    @attachment.update_columns(vt_status: "skipped")
    :skipped
  end

  def retry_later!
    @attachment.update_columns(vt_status: "scanning")
    :pending
  end
end
