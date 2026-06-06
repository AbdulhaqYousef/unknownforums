class Admin::SiteSettingsController < ApplicationController
  before_action :require_admin

  def index
    @maintenance = SiteSetting.maintenance_mode?
    @maintenance_message = SiteSetting.maintenance_message
    @selected_file_type_groups = SiteSetting.selected_file_type_groups
  end

  def update
    if params[:save_maintenance] == "1"
      SiteSetting.set(SiteSetting::MAINTENANCE_KEY, params[:maintenance_mode] == "1" ? "true" : "false")
      SiteSetting.set(SiteSetting::MAINTENANCE_MESSAGE_KEY, params[:maintenance_message].to_s.strip)
    end

    if params[:save_upload_types] == "1"
      groups = Array(params[:file_type_groups]).compact_blank
      if groups.empty?
        redirect_to admin_site_settings_path, alert: "Select at least one file type group."
        return
      end
      SiteSetting.set_allowed_file_type_groups(groups)
    end

    redirect_to admin_site_settings_path, notice: "Settings saved."
  end
end
