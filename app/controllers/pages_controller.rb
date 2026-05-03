class PagesController < ApplicationController
  def terms
    @site_page = SitePage.fetch!("terms")
  end

  def privacy
  end

  def rules
    @site_page = SitePage.fetch!("rules")
  end
end
