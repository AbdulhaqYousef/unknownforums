class AttachmentsController < ApplicationController
  before_action :set_attachment
  before_action :require_login, except: %i[show]
  before_action :authorize_attachment_access!, only: %i[show download]

  def show
    @comments   = @attachment.file_comments.visible.includes(:user).order(:created_at)
    @avg_rating = @attachment.file_comments.visible.where.not(rating: nil).average(:rating)
  end

  def download
    if @attachment.vt_warning_required? && params[:confirm] != "1"
      return render :download_warning
    end

    @attachment.increment_download!
    if logged_in?
      DownloadHistory.create!(user: current_user, attachment: @attachment, ip_address: request.ip)
      Trophy.check_and_award!(current_user)
      Trophy.check_and_award!(@attachment.user) if @attachment.user != current_user
    end
    redirect_to rails_blob_url(@attachment.file, disposition: "attachment", filename: @attachment.filename), allow_other_host: true
  end

  def approve
    require_login
    require_attachment_moderator
    @attachment.update!(approved: true)
    redirect_back fallback_location: downloads_path, notice: "File approved."
  end

  def unapprove
    require_login
    require_attachment_moderator
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
    stored_filename = AttachmentCreator.stored_filename_for(root.attachable, file.original_filename)

    new_att = Attachment.new(
      attachable:           root.attachable,
      user:                 current_user,
      filename:             stored_filename,
      content_type:         content_type,
      byte_size:            file.size,
      is_video:             content_type.start_with?("video/"),
      parent_attachment_id: root.id,
      version:              next_version,
      approved:             false
    )
    AttachmentCreator.attach_file(new_att, file, root.attachable, current_user, content_type)

    if new_att.save
      if new_att.vt_scannable?
        VirusTotalScanJob.perform_later(new_att.id)
      else
        new_att.update_columns(vt_status: "skipped", approved: true)
      end
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

  def authorize_attachment_access!
    return unless @attachment.dm_file?
    return if moderator_or_admin?

    message = @attachment.attachable
    return if message.sender == current_user || message.recipient == current_user

    redirect_to private_messages_path, alert: "You cannot access that file."
  end

  def require_attachment_moderator
    return if moderator_or_admin?
    return if attachment_category_moderator?
    redirect_to root_path, alert: "Access denied."
  end

  def attachment_category_moderator?
    return false unless current_user
    attachable = @attachment.attachable
    return false unless attachable.is_a?(Post) || attachable.is_a?(ForumThread)
    thread = attachable.is_a?(Post) ? attachable.thread : attachable
    current_user.can_moderate_category?(thread.subforum.category)
  end
end
