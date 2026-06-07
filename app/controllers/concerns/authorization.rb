module Authorization
  extend ActiveSupport::Concern

  private

  def require_admin
    unless admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_moderator
    unless moderator_or_admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_owner_or_moderator(resource)
    unless current_user == resource || moderator_or_admin?
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_category_moderator(category)
    unless current_user&.can_moderate_category?(category)
      redirect_to root_path, alert: "Access denied."
    end
  end

  def can_moderate_thread?(thread)
    return false unless current_user
    current_user.can_moderate_category?(thread.subforum.category)
  end

  def ensure_subforum_readable!(subforum)
    return if subforum.readable_by?(current_user)

    session[:return_to] = request.fullpath unless logged_in?
    message = if logged_in?
      "You do not have access to that forum."
    else
      "That forum is members only. Sign in to continue."
    end
    redirect_to(logged_in? ? root_path : login_path, alert: message)
  end
end
