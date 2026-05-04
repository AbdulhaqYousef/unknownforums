class DownloadsController < ApplicationController
  def index
    public_files = Attachment.approved.public_downloads
    @attachments = public_files.joins(:user)
                               .includes(:attachable, :file_tags, :file_comments, file_attachment: :blob)
                               .order(created_at: :desc)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @attachments = @attachments.where("attachments.filename ILIKE :query OR attachments.content_type ILIKE :query OR users.username ILIKE :query", query: query)
    end
    if params[:tag].present?
      @attachments = @attachments.joins(:file_tags).where(file_tags: { tag: params[:tag].strip.downcase })
      @active_tag  = params[:tag].strip.downcase
    end
    @popular_tags = FileTag.joins(:attachment)
                           .where(attachments: { approved: true, attachable_type: "Post" })
                           .group(:tag).order("count_all DESC").limit(20).count
    @attachments  = @attachments.page(params[:page]).per(25)
    @total_downloads = public_files.sum(:download_count)
    @total_files     = public_files.count
    @total_size      = public_files.sum(:byte_size)
  end
end
