class Admin::AttackEventsController < ApplicationController
  before_action :require_admin

  def index
    @events      = AttackEvent.recent.limit(200)
    @spike       = AttackEvent.spike?
    @top_ips     = AttackEvent.where("occurred_at > ?", 1.hour.ago)
                              .group(:ip_address)
                              .order("count_all DESC")
                              .limit(10)
                              .count
    @total_today = AttackEvent.where("occurred_at > ?", 24.hours.ago).count
  end
end
