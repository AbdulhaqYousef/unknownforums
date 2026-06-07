class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge
  belongs_to :awarded_by, class_name: "User", optional: true

  validates :badge_id, uniqueness: { scope: :user_id }
  validates :awarded_at, presence: true

  scope :recent, -> { order(awarded_at: :desc) }

  before_validation :set_awarded_at, on: :create

  private

  def set_awarded_at
    self.awarded_at ||= Time.current
  end
end
