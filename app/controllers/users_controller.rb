class UsersController < ApplicationController
  before_action :set_user, except: %i[search]
  before_action :require_login, only: %i[edit update ban unban]
  before_action :require_admin, only: %i[ban unban]

  def search
    q = params[:q].to_s.strip
    return render json: [] if q.length < 1
    users = User.where("username ILIKE ?", "#{q}%").order(:username).limit(8).pluck(:id, :username)
    render json: users.map { |id, username| { id: id, username: username } }
  end

  def show
    @threads = @user.forum_threads.order(created_at: :desc).page(params[:page]).per(10)
    @recent_posts = @user.posts.visible.includes(thread: :subforum).order(created_at: :desc).limit(10)
    Trophy.check_and_award!(@user)
    @trophies = @user.trophies.recent
    @badges = @user.badges.includes(image_attachment: :blob).ordered
  end

  def edit
    require_owner_or_moderator(@user)
  end

  def update
    require_owner_or_moderator(@user)
    user_fields = params[:user] || {}
    @user.avatar.purge if user_fields[:remove_avatar] == "1"
    @user.custom_badge.purge if user_fields[:remove_custom_badge] == "1"
    changing_password = user_params[:password].present?
    changing_email    = user_params[:email].present? && user_params[:email] != @user.email
    attrs = user_params.to_h
    attrs.delete("custom_badge") unless LevelPerks.custom_badge_allowed?(@user)
    if @user.update(attrs)
      AuditLog.record(actor: current_user, action: "password_changed", target: @user, ip: request.remote_ip) if changing_password
      AuditLog.record(actor: current_user, action: "email_changed",    target: @user, ip: request.remote_ip) if changing_email
      redirect_to user_path(@user), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def ban
    @user.update!(banned: true)
    redirect_to user_path(@user), notice: "User banned."
  end

  def unban
    @user.update!(banned: false)
    redirect_to user_path(@user), notice: "User unbanned."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = params.require(:user).permit(:email, :email_two_factor_enabled, :show_presence, :email_on_reply, :email_on_mention, :email_on_thread_reply, :signature, :password, :password_confirmation, :avatar, :custom_badge)
    if permitted[:password].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end
    permitted
  end
end
