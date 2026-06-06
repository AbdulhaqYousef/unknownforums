class Category < ApplicationRecord
  include FileTypeRestrictions

  has_many :subforums, -> { order(:position) }, dependent: :destroy
  has_many :category_moderators, dependent: :destroy
  has_many :staff, through: :category_moderators, source: :user

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:position) }
end
