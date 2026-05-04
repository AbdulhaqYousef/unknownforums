class RegistrationsController < ApplicationController
  before_action :require_guest

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      AuditLog.record(actor: @user, action: "registered", details: "New account created", ip: request.remote_ip)
      send_email_otp!
      session[:pending_email_otp_user_id] = @user.id
      session[:pending_email_otp_purpose] = "registration"
      session[:return_to_after_email_otp] = root_path
      redirect_to email_otp_path, notice: "We sent a verification code to #{@user.email}."
    else
      flash.now[:alert] = "Registration failed. Please fix the highlighted fields below."
      render :new, status: :unprocessable_entity
    end
  rescue EmailOtpSender::DeliveryDisabled, EmailOtpSender::DeliveryFailed, Net::SMTPError, IOError, Timeout::Error, SocketError => error
    Rails.logger.warn("Registration email OTP delivery failed: #{error.class}: #{error.message}")
    @user.destroy if @user&.persisted? && !@user.email_verified?
    @user ||= User.new(registration_params)
    @user.errors.add(:base, "We could not send the verification email. Please try again.")
    flash.now[:alert] = "Registration failed because the verification email could not be sent."
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotUnique
    @user ||= User.new(registration_params)
    @user.errors.add(:base, "That username or email is already taken.")
    flash.now[:alert] = "Registration failed. That username or email is already taken."
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  def send_email_otp!
    EmailOtpSender.call(user: @user, purpose: :registration)
  end
end
