class Attachment < ApplicationRecord
  ALLOWED_TYPES = %w[
    image/jpeg image/png image/gif image/webp
    application/pdf text/plain
    application/zip application/x-zip-compressed
    video/mp4 video/webm video/ogg
  ].freeze

  BLOCKED_EXTENSIONS = %w[exe bat cmd sh ps1 vbs js dll msi dmg].freeze
  MAX_SIZE = 100.megabytes

  belongs_to :attachable, polymorphic: true
  belongs_to :user
  belongs_to :parent_attachment, class_name: "Attachment", optional: true
  has_many   :versions, class_name: "Attachment", foreign_key: :parent_attachment_id, dependent: :destroy
  has_one_attached :file

  validates :filename, presence: true
  validates :content_type, inclusion: { in: ALLOWED_TYPES, message: "is not an allowed file type" }
  validates :byte_size, numericality: { less_than_or_equal_to: MAX_SIZE, message: "exceeds 100MB limit" }
  validate :extension_not_blocked

  VT_STATUSES = %w[pending scanning clean suspicious malicious skipped].freeze

  scope :approved,         -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }
  scope :vt_pending,       -> { where(vt_status: "pending") }
  scope :vt_malicious,     -> { where(vt_status: "malicious") }
  scope :top_downloads,    -> { order(download_count: :desc) }

  def vt_scannable?
    %w[application/zip application/x-zip-compressed application/pdf
       application/octet-stream text/plain].include?(content_type)
  end

  def vt_clean?()       vt_status == "clean"      end
  def vt_malicious?()   vt_status == "malicious"  end
  def vt_pending?()     vt_status == "pending"     end
  def vt_scanning?()    vt_status == "scanning"    end
  def vt_suspicious?()  vt_status == "suspicious"  end
  def vt_skipped?()     vt_status == "skipped"     end

  def vt_warning_required?
    vt_scannable? && !vt_clean?
  end

  def vt_status_label
    case vt_status
    when "clean"      then "VT Clean"
    when "suspicious" then "VT Suspicious"
    when "malicious"  then "VT Malicious"
    when "scanning"   then "VT Scanning"
    when "pending"    then "VT Pending"
    when "skipped"    then "VT Not Scanned"
    else "VT Unknown"
    end
  end

  def vt_warning_message
    case vt_status
    when "malicious"
      "VirusTotal detected this file as malicious. Download only if you fully trust the source."
    when "suspicious"
      "VirusTotal flagged this file as suspicious. This file might be unsafe, so watch out."
    when "pending", "scanning"
      "This file has not finished scanning yet. This file might be unsafe, so watch out."
    when "skipped"
      "This file could not be scanned by VirusTotal. This file might be unsafe, so watch out."
    else
      "This file might be unsafe, so watch out."
    end
  end

  def root_attachment
    parent_attachment || self
  end

  def all_versions
    root_attachment.versions.order(:version)
  end

  def latest_version?
    versions.empty?
  end

  def video?
    content_type.start_with?("video/")
  end

  def image?
    content_type.start_with?("image/")
  end

  def human_size
    ActiveSupport::NumberHelper.number_to_human_size(byte_size)
  end

  def increment_download!
    increment!(:download_count)
  end

  private

  def extension_not_blocked
    ext = File.extname(filename).delete(".").downcase
    errors.add(:filename, "has a blocked extension") if BLOCKED_EXTENSIONS.include?(ext)
  end
end
