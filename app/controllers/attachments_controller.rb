class AttachmentsController < ApplicationController
  before_action :set_attachment

  def show
  end

  def download
    @attachment.increment_download!
    redirect_to rails_blob_url(@attachment.file), allow_other_host: true
  end

  def approve
    require_login
    require_admin
    @attachment.update!(approved: true)
    redirect_back fallback_location: downloads_path, notice: "File approved."
  end

  def unapprove
    require_login
    require_admin
    @attachment.update!(approved: false)
    redirect_back fallback_location: downloads_path, notice: "File approval revoked."
  end

  def destroy
    require_login
    require_owner_or_moderator(@attachment.user)
    @attachment.destroy
    redirect_back fallback_location: root_path, notice: "Attachment deleted."
  end

  private

  def set_attachment
    @attachment = Attachment.find(params[:id])
  end
end
