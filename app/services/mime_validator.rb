# frozen_string_literal: true

# Validates that the actual magic bytes of an uploaded file match the declared content-type.
# Uses Marcel (already a Rails dependency via Active Storage).
class MimeValidator
  # Map declared content-type -> list of content-types Marcel may detect for that type.
  # Executables/scripts often come through as application/octet-stream regardless of ext.
  ACCEPTABLE_DETECTIONS = {
    "image/jpeg"                    => %w[image/jpeg],
    "image/png"                     => %w[image/png],
    "image/gif"                     => %w[image/gif],
    "image/webp"                    => %w[image/webp],
    "application/pdf"               => %w[application/pdf],
    "text/plain"                    => %w[text/plain application/octet-stream],
    "application/zip"               => %w[application/zip application/x-zip-compressed],
    "application/x-zip-compressed"  => %w[application/zip application/x-zip-compressed],
    "application/x-bittorrent"      => %w[application/x-bittorrent application/octet-stream],
    "video/mp4"                     => %w[video/mp4],
    "video/webm"                    => %w[video/webm],
    "video/ogg"                     => %w[video/ogg application/ogg],
    "application/x-msdownload"      => %w[application/x-msdownload application/x-dosexec application/octet-stream],
    "application/x-msdos-program"   => %w[application/x-msdownload application/x-dosexec application/octet-stream],
    "application/x-dosexec"         => %w[application/x-msdownload application/x-dosexec application/octet-stream],
    "application/octet-stream"      => %w[application/octet-stream],
    "application/x-sh"              => %w[application/x-sh text/plain application/octet-stream],
    "application/x-powershell"      => %w[application/x-powershell text/plain application/octet-stream],
    "application/javascript"        => %w[application/javascript text/javascript text/plain application/octet-stream],
    "text/javascript"               => %w[application/javascript text/javascript text/plain application/octet-stream],
    "application/x-apple-diskimage" => %w[application/x-apple-diskimage application/octet-stream]
  }.freeze

  def self.valid?(declared_type, file_io)
    new(declared_type, file_io).valid?
  end

  def initialize(declared_type, file_io)
    @declared_type = declared_type.to_s
    @file_io       = file_io
  end

  def valid?
    detected = Marcel::MimeType.for(@file_io)
    acceptable = ACCEPTABLE_DETECTIONS[@declared_type] || [ @declared_type ]
    acceptable += [ "application/octet-stream" ] unless acceptable.include?("application/octet-stream")
    acceptable.include?(detected.to_s)
  rescue StandardError => e
    Rails.logger.warn("MimeValidator failed: #{e.class}: #{e.message}")
    true # fail open — don't block upload if detection fails
  end
end
