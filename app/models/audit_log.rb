class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User", optional: true

  scope :recent, -> { order(created_at: :desc) }

  def self.record(actor: nil, action:, target: nil, details: nil, ip: nil)
    create!(
      actor:       actor,
      action:      action.to_s,
      target_type: target&.class&.name,
      target_id:   target&.id,
      details:     details,
      ip_address:  ip
    )
  rescue => e
    Rails.logger.error("AuditLog.record failed: #{e.message}")
  end
end
