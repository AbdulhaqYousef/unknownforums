class SessionsController < ApplicationController
  before_action :require_guest, only: %i[new create]

  def new
  end

  def create
    user = User.find_by("LOWER(username) = ?", params[:username].to_s.downcase.strip)
    return_to = session[:return_to].presence || root_path

    if user&.locked?
      flash.now[:alert] = "Account locked. Try again in #{user.lockout_remaining} minutes."
      return render :new, status: :unprocessable_entity
    end

    if user&.authenticate(params[:password])
      unless user.email.present?
        flash.now[:alert] = "This account needs an email address before it can use email 2FA."
        return render :new, status: :unprocessable_entity
      end

      reset_session
      send_email_otp!(user)
      session[:pending_email_otp_user_id] = user.id
      session[:pending_email_otp_purpose] = "login"
      session[:return_to_after_email_otp] = return_to
      redirect_to email_otp_path, notice: "We sent a login code to #{user.email}."
    else
      user&.register_failed_login!
      remaining = User::MAX_LOGIN_ATTEMPTS - (user&.failed_login_attempts || 0)
      alert_msg = "Invalid username or password."
      alert_msg += " #{remaining} attempt(s) remaining." if user && remaining > 0 && remaining < 3
      alert_msg = "Account locked for #{User::LOCKOUT_DURATION / 60} minutes." if user&.locked?
      flash.now[:alert] = alert_msg
      render :new, status: :unprocessable_entity
    end
  rescue EmailOtpSender::DeliveryDisabled, Net::SMTPError, IOError, Timeout::Error, SocketError => error
    Rails.logger.warn("Login email OTP delivery failed: #{error.class}: #{error.message}")
    flash.now[:alert] = "We could not send your login code. Please try again."
    render :new, status: :unprocessable_entity
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def send_email_otp!(user)
    EmailOtpSender.call(user: user, purpose: :login)
  end
end
