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
  has_one_attached :file

  validates :filename, presence: true
  validates :content_type, inclusion: { in: ALLOWED_TYPES, message: "is not an allowed file type" }
  validates :byte_size, numericality: { less_than_or_equal_to: MAX_SIZE, message: "exceeds 100MB limit" }
  validate :extension_not_blocked

  scope :approved, -> { where(approved: true) }
  scope :pending_approval, -> { where(approved: false) }

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
