class Admin::UserWarningsController < ApplicationController
  before_action :require_admin
  before_action :set_user
  before_action :set_warning, only: %i[destroy]

  def create
    @warning = @user.warnings.build(warning_params.merge(warned_by: current_user))
    if @warning.save
      redirect_to admin_user_path(@user), notice: "Warning issued."
    else
      redirect_to admin_user_path(@user), alert: @warning.errors.full_messages.join(", ")
    end
  end

  def destroy
    @warning.destroy
    redirect_to admin_user_path(@user), notice: "Warning removed."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_warning
    @warning = @user.warnings.find(params[:id])
  end

  def warning_params
    params.require(:user_warning).permit(:reason, :severity, :expires_at)
  end
end
