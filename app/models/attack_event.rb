class AttackEvent < ApplicationRecord
  validates :ip_address, :matched, :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }

  def self.log(request, matched)
    create!(
      ip_address: request.ip.to_s,
      matched:    matched.to_s,
      path:       request.path.to_s.truncate(200),
      user_agent: request.user_agent.to_s.truncate(300),
      occurred_at: Time.current
    )
  rescue => e
    Rails.logger.error("AttackEvent.log failed: #{e.message}")
  end

  def self.spike?(window: 5.minutes, threshold: 20)
    where("occurred_at > ?", window.ago).count >= threshold
  end
end
