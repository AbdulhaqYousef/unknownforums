class Admin::CategoryModeratorsController < ApplicationController
  before_action :require_admin
  before_action :set_category

  def index
    @staff = @category.staff.order(:username)
    @available_users = User.where.not(id: @staff.pluck(:id)).order(:username)
  end

  def create
    user = User.find(params[:user_id])
    @category.category_moderators.find_or_create_by!(user: user)
    redirect_to admin_category_category_moderators_path(@category), notice: "#{user.username} added as staff for #{@category.name}."
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_category_category_moderators_path(@category), alert: "Could not add staff member."
  end

  def destroy
    cm = @category.category_moderators.find(params[:id])
    user = cm.user
    cm.destroy
    redirect_to admin_category_category_moderators_path(@category), notice: "#{user.username} removed from #{@category.name} staff."
  end

  private

  def set_category
    @category = Category.find(params[:category_id])
  end
end
