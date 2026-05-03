class UserWarning < ApplicationRecord
  SEVERITIES = { minor: 0, moderate: 1, severe: 2 }.freeze

  belongs_to :user
  belongs_to :warned_by, class_name: "User"

  validates :reason,   presence: true
  validates :severity, inclusion: { in: SEVERITIES.values }

  enum :severity, SEVERITIES

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }
end
