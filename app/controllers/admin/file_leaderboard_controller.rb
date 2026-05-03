class Admin::FileLeaderboardController < ApplicationController
  before_action :require_admin

  def index
    @top_files    = Attachment.includes(:user).top_downloads.limit(50)
    @total_dl     = Attachment.sum(:download_count)
    @malicious    = Attachment.vt_malicious.includes(:user).order(created_at: :desc).limit(20)
    @pending_scan = Attachment.vt_pending.count
  end
end
