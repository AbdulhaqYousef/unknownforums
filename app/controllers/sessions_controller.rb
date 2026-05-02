class SessionsController < ApplicationController
  before_action :require_guest, only: %i[new create]

  def new
  end

  def create
    user = User.find_by("LOWER(username) = ?", params[:username].to_s.downcase.strip)

    if user&.locked?
      flash.now[:alert] = "Account locked. Try again in #{user.lockout_remaining} minutes."
      return render :new, status: :unprocessable_entity
    end

    if user&.authenticate(params[:password])
      user.register_successful_login!(ip: request.remote_ip)
      reset_session
      session[:user_id] = user.id
      redirect_to session.delete(:return_to) || root_path, notice: "Welcome back, #{user.username}!"
    else
      user&.register_failed_login!
      remaining = User::MAX_LOGIN_ATTEMPTS - (user&.failed_login_attempts || 0)
      alert_msg = "Invalid username or password."
      alert_msg += " #{remaining} attempt(s) remaining." if user && remaining > 0 && remaining < 3
      alert_msg = "Account locked for #{User::LOCKOUT_DURATION / 60} minutes." if user&.locked?
      flash.now[:alert] = alert_msg
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have been logged out."
  end
end
