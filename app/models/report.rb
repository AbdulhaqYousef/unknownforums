class Report < ApplicationRecord
  REPORTABLE_TYPES = %w[Post ForumThread User].freeze

  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many_attached :screenshots

  enum :status, { pending: 0, reviewed: 1, resolved: 2, dismissed: 3 }

  validates :reason, presence: true, length: { minimum: 10, maximum: 1000 }
  validate :valid_screenshots

  private

  def valid_screenshots
    screenshots.each do |file|
      unless file.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
        errors.add(:screenshots, "must be images (JPEG, PNG, GIF, WebP)")
      end
      if file.byte_size > 10.megabytes
        errors.add(:screenshots, "must be under 10MB each")
      end
    end
  end
end
