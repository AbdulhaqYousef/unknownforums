class SitemapsController < ApplicationController
  skip_before_action :check_maintenance_mode

  before_action :set_sitemap_url_options

  def show
    @subforums = readable_subforums.includes(:category).order(:position, :name)
    @threads = ForumThread.joins(:subforum)
                          .where(subforum_id: @subforums.select(:id))
                          .includes(:subforum)
                          .order(updated_at: :desc)
                          .limit(5000)
    @users = User.where(banned: false).order(updated_at: :desc).limit(2000)
    @attachments = readable_attachments
                     .where(parent_attachment_id: nil)
                     .order(updated_at: :desc)
                     .limit(5000)

    respond_to do |format|
      format.xml
    end
  end

  private

  def set_sitemap_url_options
    opts = {
      host: ENV.fetch("APP_HOST", request.host),
      protocol: request.ssl? ? "https" : "http"
    }
    Rails.application.routes.default_url_options.merge!(opts)
    @default_url_options = opts
  end

  def readable_subforums
    return Subforum.publicly_readable if subforum_access_columns?

    Subforum.all
  end

  def readable_attachments
    scope = Attachment.approved.public_downloads
    return scope.in_readable_subforums(nil) if subforum_access_columns?

    scope
  end

  def subforum_access_columns?
    Subforum.column_names.include?("public_read") && Category.column_names.include?("public_read")
  end
end