class VirusTotalQuota < ApplicationRecord
  self.table_name = "virus_total_quotas"

  LIMITS = {
    minute: 4,
    day: 500,
    month: 15_500
  }.freeze

  class RateLimited < StandardError
    attr_reader :wait_seconds

    def initialize(wait_seconds)
      @wait_seconds = wait_seconds
      super("VirusTotal quota exhausted; retry in #{wait_seconds} seconds")
    end
  end

  def self.consume!
    now = Time.current
    periods = period_windows(now)

    transaction do
      rows = periods.map do |period, config|
        find_or_create_by!(period: period.to_s, period_start: config.fetch(:start))
      end

      rows.each(&:lock!)
      exhausted = rows.find { |row| row.count >= LIMITS.fetch(row.period.to_sym) }

      if exhausted
        wait_until = periods.fetch(exhausted.period.to_sym).fetch(:finish)
        raise RateLimited, [ (wait_until - now).ceil, 60 ].max
      end

      rows.each { |row| row.increment!(:count) }
    end

    true
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.period_windows(now)
    {
      minute: {
        start: now.beginning_of_minute,
        finish: now.beginning_of_minute + 1.minute
      },
      day: {
        start: now.beginning_of_day,
        finish: now.beginning_of_day + 1.day
      },
      month: {
        start: now.beginning_of_month,
        finish: now.beginning_of_month.next_month
      }
    }
  end
end
