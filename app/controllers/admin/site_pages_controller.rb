class Admin::SitePagesController < ApplicationController
  before_action :require_admin
  before_action :set_site_page, only: %i[edit update]

  def index
    @site_pages = SitePage::DEFAULTS.keys.map { |slug| SitePage.fetch!(slug) }
  end

  def edit
  end

  def update
    if @site_page.update(site_page_params.merge(updated_by: current_user))
      redirect_to admin_site_pages_path, notice: "Page updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_site_page
    @site_page = SitePage.find(params[:id])
  end

  def site_page_params
    params.require(:site_page).permit(:title, :body_html, :body_format)
  end
end
