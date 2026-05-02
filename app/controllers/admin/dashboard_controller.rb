class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    @total_users = User.count
    @total_threads = ForumThread.count
    @total_posts = Post.count
    @total_files = Attachment.count
    @pending_reports = Report.pending.count
    @locked_threads = ForumThread.where(locked: true).count
    @pinned_threads = ForumThread.where(pinned: true).count
    @banned_users = User.where(banned: true).count
    @total_downloads = Attachment.sum(:download_count)
    @recent_users = User.order(created_at: :desc).limit(10)
    @recent_threads = ForumThread.includes(:user, :subforum).order(created_at: :desc).limit(10)
  end
end
