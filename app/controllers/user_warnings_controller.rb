# frozen_string_literal: true

class UserWarningsController < ApplicationController
  before_action :require_login

  def index
    @warnings = current_user.warnings.active.recent.includes(:warned_by)
  end

  def acknowledge
    warning = current_user.warnings.find(params[:id])
    warning.update!(acknowledged: true)
    redirect_to user_warnings_path, notice: "Warning acknowledged."
  end

  def acknowledge_all
    current_user.warnings.active.where(acknowledged: false).update_all(acknowledged: true, updated_at: Time.current)
    redirect_to user_warnings_path, notice: "All warnings acknowledged."
  end
end
