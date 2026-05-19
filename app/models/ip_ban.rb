class IpBan < ApplicationRecord
  belongs_to :banned_by, class_name: "User", optional: true

  validates :ip_address, presence: true, uniqueness: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  after_commit :bust_cache

  def self.banned?(ip)
    str = ip.to_s
    Rails.cache.fetch("ip_ban:#{str}", expires_in: 5.minutes) do
      active.exists?(ip_address: str)
    end
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def bust_cache
    Rails.cache.delete("ip_ban:#{ip_address}")
  end
end
