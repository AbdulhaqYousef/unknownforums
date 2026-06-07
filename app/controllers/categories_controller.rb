class CategoriesController < ApplicationController
  before_action :set_category, only: :show
  before_action :ensure_category_access, only: :show

  def index
    redirect_to root_path
  end

  def show
    @subforums = @category.subforums.order(:position, :name)
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def ensure_category_access
    return if @category.readable_by?(current_user)

    session[:return_to] = request.fullpath unless logged_in?
    message = if logged_in?
      "You do not have access to that category."
    else
      "That category is members only. Sign in to continue."
    end
    redirect_to(logged_in? ? root_path : login_path, alert: message)
  end
end
