class AttachmentsController < ApplicationController
  before_action :set_attachment

  def show
  end

  def download
    if @attachment.vt_warning_required? && params[:confirm] != "1"
      return render :download_warning
    end

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

  def new_version
    require_login
    require_owner_or_moderator(@attachment.root_attachment.user)
  end

  def upload_version
    require_login
    root = @attachment.root_attachment
    require_owner_or_moderator(root.user)

    file = params[:file]
    unless file.respond_to?(:original_filename)
      return redirect_to new_version_attachment_path(@attachment), alert: "Please select a file."
    end

    content_type = file.content_type.presence || "application/octet-stream"
    next_version  = root.versions.maximum(:version).to_i + 2

    new_att = Attachment.new(
      attachable:           root.attachable,
      user:                 current_user,
      filename:             file.original_filename,
      content_type:         content_type,
      byte_size:            file.size,
      is_video:             content_type.start_with?("video/"),
      parent_attachment_id: root.id,
      version:              next_version,
      approved:             false
    )
    new_att.file.attach(file)

    if new_att.save
      VirusTotalScanJob.perform_later(new_att.id) if new_att.vt_scannable?
      redirect_back fallback_location: root_path, notice: "Version #{next_version} uploaded."
    else
      redirect_to new_version_attachment_path(@attachment),
        alert: new_att.errors.full_messages.join(", ")
    end
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
