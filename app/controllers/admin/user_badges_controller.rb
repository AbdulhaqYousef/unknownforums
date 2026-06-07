class Admin::UserBadgesController < ApplicationController
  before_action :require_admin
  before_action :set_user

  def create
    badge = Badge.find(params[:badge_id])
    user_badge = @user.user_badges.build(badge: badge, awarded_by: current_user)
    if user_badge.save
      redirect_to admin_user_path(@user), notice: "Badge \"#{badge.name}\" awarded."
    else
      redirect_to admin_user_path(@user), alert: user_badge.errors.full_messages.to_sentence
    end
  end

  def destroy
    user_badge = @user.user_badges.find(params[:id])
    name = user_badge.badge.name
    user_badge.destroy
    redirect_to admin_user_path(@user), notice: "Badge \"#{name}\" removed."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
