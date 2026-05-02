class RegistrationsController < ApplicationController
  before_action :require_guest

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome to the forum, #{@user.username}!"
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @user ||= User.new(registration_params)
    @user.errors.add(:base, "That username or email is already taken.")
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
