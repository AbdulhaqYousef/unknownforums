class UsersController < ApplicationController
  before_action :set_user
  before_action :require_login, only: %i[edit update ban unban]
  before_action :require_admin, only: %i[ban unban]

  def show
    @threads  = @user.forum_threads.order(created_at: :desc).page(params[:page]).per(15)
    @posts    = @user.posts.visible.order(created_at: :desc).page(params[:page]).per(15)
    Trophy.check_and_award!(@user)
    @trophies = @user.trophies.recent
  end

  def edit
    require_owner_or_moderator(@user)
  end

  def update
    require_owner_or_moderator(@user)
    @user.avatar.purge if params[:user][:remove_avatar] == "1"
    if @user.update(user_params)
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
    permitted = params.require(:user).permit(:email, :email_two_factor_enabled, :show_presence, :email_on_reply, :email_on_mention, :email_on_thread_reply, :signature, :password, :password_confirmation, :avatar)
    if permitted[:password].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end
    permitted
  end
end
