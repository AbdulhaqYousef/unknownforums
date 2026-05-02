module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  private

  def require_login
    unless logged_in?
      session[:return_to] = request.fullpath
      redirect_to login_path, alert: "You must be logged in to do that."
    end
  end

  def require_guest
    redirect_to root_path, notice: "You are already logged in." if logged_in?
  end
end
