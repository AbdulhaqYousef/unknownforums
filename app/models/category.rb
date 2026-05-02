class Category < ApplicationRecord
  has_many :subforums, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  default_scope { order(:position) }
end
