class EmailOtpsController < ApplicationController
  before_action :require_guest
  before_action :set_pending_user

  def show
  end

  def create
    if @user.verify_email_otp(params[:code], purpose: @purpose)
      complete_login
    else
      flash.now[:alert] = otp_error_message
      render :show, status: :unprocessable_entity
    end
  end

  def resend
    if @user.email_otp_resend_allowed?
      send_otp!
      redirect_to email_otp_path, notice: "A new code was sent to #{@user.email}."
    else
      redirect_to email_otp_path, alert: "Please wait #{@user.email_otp_resend_wait} seconds before requesting another code."
    end
  rescue EmailOtpSender::DeliveryDisabled, Net::SMTPError, IOError, Timeout::Error, SocketError => error
    Rails.logger.warn("Email OTP resend failed: #{error.class}: #{error.message}")
    redirect_to email_otp_path, alert: "We could not send a new code. Please try again."
  end

  private

  def set_pending_user
    @user = User.find_by(id: session[:pending_email_otp_user_id])
    @purpose = session[:pending_email_otp_purpose]
    return if @user && @purpose.present?

    redirect_to login_path, alert: "Please log in first."
  end

  def send_otp!
    EmailOtpSender.call(user: @user, purpose: @purpose)
  end

  def complete_login
    destination = session[:return_to_after_email_otp].presence || root_path
    reset_session
    @user.register_successful_login!(ip: request.remote_ip)
    session[:user_id] = @user.id
    redirect_to destination, notice: "Welcome, #{@user.username}!"
  end

  def otp_error_message
    if !@user.email_otp_valid_for?(@purpose)
      "That code has expired. Please request a new one."
    elsif @user.email_otp_attempts >= User::EMAIL_OTP_MAX_ATTEMPTS
      "Too many incorrect codes. Please request a new one."
    else
      "Invalid verification code."
    end
  end
end
