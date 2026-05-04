class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::RoutingError, with: :not_found

  before_action :set_current_user
  before_action :prevent_html_caching
  before_action :track_current_user_activity
  before_action :check_banned
  before_action :set_admin_summary, if: :show_admin_summary?

  helper_method :current_user, :logged_in?, :admin?, :moderator_or_admin?, :can_moderate_thread?

  private

  def set_current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_user
    @current_user
  end

  def logged_in?
    current_user.present?
  end

  def prevent_html_caching
    return unless request.format.html?

    response.headers["Cache-Control"] = "no-store, no-cache, max-age=0, must-revalidate, private"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def track_current_user_activity
    return unless current_user&.has_attribute?(:last_seen_at)
    return if current_user.last_seen_at.present? && current_user.last_seen_at > 2.minutes.ago

    current_user.update_column(:last_seen_at, Time.current)
  end

  def admin?
    current_user&.admin?
  end

  def moderator_or_admin?
    current_user&.can_moderate?
  end

  def check_banned
    if current_user&.banned?
      reset_session
      redirect_to login_path, alert: "Your account has been banned."
    end
  end

  def show_admin_summary?
    controller_path.start_with?("admin/") && moderator_or_admin?
  end

  def set_admin_summary
    @admin_summary = {
      users: User.count,
      threads: ForumThread.count,
      posts: Post.count,
      pending_reports: Report.pending.count,
      files: Attachment.count,
      pending_files: Attachment.pending_approval.count
    }
  end

  def not_found
    respond_to do |format|
      format.html { render file: Rails.root.join("public/404.html"), layout: false, status: :not_found }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.any  { head :not_found }
    end
  end
end
