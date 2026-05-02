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
end
