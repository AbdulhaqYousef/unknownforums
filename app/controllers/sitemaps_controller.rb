class SitemapsController < ApplicationController
  skip_before_action :check_maintenance_mode
  skip_before_action :check_ip_banned
  skip_before_action :check_banned
  skip_before_action :track_current_user_activity
  skip_before_action :set_admin_summary
  skip_before_action :set_active_warnings

  before_action :disable_session
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

    xml = render_to_string(formats: [ :xml ], layout: false)
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
    response.headers["Cache-Control"] = "public, max-age=3600, s-maxage=86400"
    render plain: xml, content_type: "application/xml"
  end

  private

  def disable_session
    request.session_options[:skip] = true
  end

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