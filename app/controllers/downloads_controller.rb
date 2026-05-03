class DownloadsController < ApplicationController
  def index
    @attachments = Attachment.approved.joins(:user).includes(:attachable, file_attachment: :blob)
                             .order(created_at: :desc)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @attachments = @attachments.where("attachments.filename ILIKE :query OR attachments.content_type ILIKE :query OR users.username ILIKE :query", query: query)
    end
    @attachments = @attachments.page(params[:page]).per(25)
    @total_downloads = Attachment.approved.sum(:download_count)
    @total_files = Attachment.approved.count
    @total_size = Attachment.approved.sum(:byte_size)
  end
end
