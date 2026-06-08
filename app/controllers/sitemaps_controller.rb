class SitemapsController < ApplicationController
  content_security_policy false

  skip_before_action :check_maintenance_mode
  skip_before_action :check_ip_banned
  skip_before_action :check_banned
  skip_before_action :track_current_user_activity
  skip_before_action :set_admin_summary
  skip_before_action :set_active_warnings

  before_action :disable_session
  before_action :disable_conditional_get
  before_action :set_sitemap_url_options

  after_action :strip_sitemap_cache_validators

  def show
    assigns = SitemapData.load
    @subforums = assigns[:subforums]
    @threads = assigns[:threads]
    @users = assigns[:users]
    @attachments = assigns[:attachments]

    xml = render_to_string(formats: [ :xml ], layout: false)
    response.headers["Content-Type"] = "application/xml; charset=utf-8"
    response.headers["Cache-Control"] = "public, max-age=3600"
    render plain: xml, content_type: "application/xml"
  end

  private

  def disable_session
    request.session_options[:skip] = true
  end

  def disable_conditional_get
    request.env["HTTP_IF_NONE_MATCH"] = nil
    request.env["HTTP_IF_MODIFIED_SINCE"] = nil
  end

  def strip_sitemap_cache_validators
    response.headers.delete("ETag")
    response.headers.delete("Last-Modified")
  end

  def set_sitemap_url_options
    opts = {
      host: ENV.fetch("APP_HOST", "unknownforums.fun"),
      protocol: "https"
    }
    Rails.application.routes.default_url_options.merge!(opts)
    @default_url_options = opts
  end
end