class Admin::StaffNotesController < ApplicationController
  before_action :require_admin
  before_action :set_user
  before_action :set_note, only: %i[destroy]

  def create
    @note = @user.staff_notes.build(body: params[:staff_note][:body], author: current_user)
    if @note.save
      redirect_to admin_user_path(@user), notice: "Note added."
    else
      redirect_to admin_user_path(@user), alert: "Note cannot be blank."
    end
  end

  def destroy
    @note.destroy
    redirect_to admin_user_path(@user), notice: "Note deleted."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_note
    @note = @user.staff_notes.find(params[:id])
  end
end
