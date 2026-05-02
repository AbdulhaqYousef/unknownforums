class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: %i[show edit update ban unban flag unflag]

  def index
    @users = User.order(created_at: :desc)
    @users = search_users(@users) if params[:q].present?
    @users = @users.where(role: params[:role]) if params[:role].present? && User.roles.key?(params[:role])
    @users = @users.where(banned: true) if params[:status] == "banned"
    @users = @users.where(flagged: true) if params[:status] == "flagged"
    @users = @users.where(banned: false, flagged: false) if params[:status] == "active"
    @users = @users.page(params[:page])
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def ban
    @user.update!(banned: true)
    redirect_back fallback_location: admin_users_path, notice: "User banned."
  end

  def unban
    @user.update!(banned: false)
    redirect_back fallback_location: admin_users_path, notice: "User unbanned."
  end

  def flag
    @user.update!(flagged: true, flag_reason: params[:flag_reason].presence || @user.flag_reason)
    redirect_back fallback_location: admin_users_path, notice: "User flagged."
  end

  def unflag
    @user.update!(flagged: false, flag_reason: nil)
    redirect_back fallback_location: admin_users_path, notice: "User unflagged."
  end

  private

  def search_users(users)
    query = params[:q].to_s.strip
    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    users.where(
      "username ILIKE :pattern OR email ILIKE :pattern OR moderation_note ILIKE :pattern OR flag_reason ILIKE :pattern OR EXISTS (SELECT 1 FROM unnest(previous_usernames) old_name WHERE old_name ILIKE :pattern)",
      pattern: pattern
    )
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role, :banned, :flagged, :flag_reason, :moderation_note, :reputation)
  end
end
