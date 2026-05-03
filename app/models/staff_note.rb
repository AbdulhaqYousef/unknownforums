class StaffNote < ApplicationRecord
  belongs_to :user
  belongs_to :author, class_name: "User"

  validates :body, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
