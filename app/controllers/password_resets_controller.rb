class PasswordResetsController < ApplicationController
  before_action :require_guest

  def new
  end

  def create
    user = User.find_by("LOWER(email) = ?", params[:email].to_s.strip.downcase)
    if user&.email.present?
      token = user.generate_password_reset_token!
      UserMailer.password_reset(user, token).deliver_later(queue: :mailers)
      AuditLog.record(actor: user, action: "password_reset_requested", ip: request.remote_ip)
    end
    # Always show same message to prevent email enumeration
    redirect_to login_path, notice: "If that email is registered, you'll receive a reset link shortly."
  end

  def edit
    @token = params[:id]
    @user  = User.find_by_reset_token(@token)
    if @user.nil? || !@user.password_reset_token_valid?
      redirect_to new_password_reset_path, alert: "That reset link is invalid or has expired."
    end
  end

  def update
    @token = params[:id]
    @user  = User.find_by_reset_token(@token)

    if @user.nil? || !@user.password_reset_token_valid?
      redirect_to new_password_reset_path, alert: "That reset link is invalid or has expired."
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset!
      AuditLog.record(actor: @user, action: "password_reset_completed", ip: request.remote_ip)
      redirect_to login_path, notice: "Password updated. You can now sign in."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
