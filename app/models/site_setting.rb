class SiteSetting < ApplicationRecord
  MAINTENANCE_KEY = "maintenance_mode".freeze
  MAINTENANCE_MESSAGE_KEY = "maintenance_message".freeze

  validates :key, presence: true, uniqueness: true

  def self.get(key)
    Rails.cache.fetch("site_setting:#{key}", expires_in: 1.minute) do
      find_by(key: key)&.value
    end
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key)
    record.value = value.to_s
    record.save!
    Rails.cache.delete("site_setting:#{key}")
  end

  def self.maintenance_mode?
    get(MAINTENANCE_KEY) == "true"
  end

  def self.maintenance_message
    get(MAINTENANCE_MESSAGE_KEY).presence || "The site is undergoing maintenance. We'll be back shortly."
  end
end
