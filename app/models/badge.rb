class Badge < ApplicationRecord
  has_one_attached :image
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  def self.feature_available?
    return @feature_available unless @feature_available.nil?

    @feature_available = connection.data_source_exists?("badges") &&
                         connection.data_source_exists?("user_badges")
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError
    @feature_available = false
  end

  IMAGE_TYPES = %w[image/gif image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 10.megabytes

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :position, numericality: { only_integer: true }
  validate :image_format, if: -> { image.attached? }

  scope :ordered, -> { order(:position, :name) }

  private

  def image_format
    unless IMAGE_TYPES.include?(image.content_type)
      errors.add(:image, "must be a GIF, PNG, JPEG, or WebP image")
    end
    if image.byte_size > IMAGE_MAX_SIZE
      errors.add(:image, "must be smaller than 10MB")
    end
  end
end
