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
      if user.email_two_factor_enabled?
        unless user.email.present?
          flash.now[:alert] = "This account needs an email address before it can use email 2FA."
          return render :new, status: :unprocessable_entity
        end

        reset_session
        send_email_otp!(user)
        session[:pending_email_otp_user_id] = user.id
        session[:pending_email_otp_purpose] = "login"
        session[:return_to_after_email_otp] = return_to
        AuditLog.record(actor: user, action: "login_2fa_initiated", details: "Email OTP sent", ip: request.remote_ip)
        redirect_to email_otp_path, notice: "We sent a login code to #{user.email}.", status: :see_other
      else
        user.register_successful_login!(ip: request.remote_ip)
        reset_session
        session[:user_id] = user.id
        AuditLog.record(actor: user, action: "login_success", details: "Direct login", ip: request.remote_ip)
        redirect_to return_to, notice: "Welcome back, #{user.username}!", status: :see_other
      end
    else
      user&.register_failed_login!
      AuditLog.record(actor: user, action: "login_failed", details: "Username: #{params[:username].to_s.strip.first(60)}", ip: request.remote_ip)
      remaining = User::MAX_LOGIN_ATTEMPTS - (user&.failed_login_attempts || 0)
      alert_msg = "Invalid username or password."
      alert_msg += " #{remaining} attempt(s) remaining." if user && remaining > 0 && remaining < 3
      alert_msg = "Account locked for #{User::LOCKOUT_DURATION / 60} minutes." if user&.locked?
      flash.now[:alert] = alert_msg
      render :new, status: :unprocessable_entity
    end
  rescue EmailOtpSender::DeliveryDisabled, EmailOtpSender::DeliveryFailed, Net::SMTPError, IOError, Timeout::Error, SocketError => error
    Rails.logger.warn("Login email OTP delivery failed: #{error.class}: #{error.message}")
    flash.now[:alert] = "We could not send your login code. Please try again."
    render :new, status: :unprocessable_entity
  end

  def destroy
    AuditLog.record(actor: current_user, action: "logout", ip: request.remote_ip) if current_user
    reset_session
    redirect_to root_path, notice: "You have been logged out.", status: :see_other
  end

  private

  def send_email_otp!(user)
    EmailOtpSender.call(user: user, purpose: :login)
  end
end
