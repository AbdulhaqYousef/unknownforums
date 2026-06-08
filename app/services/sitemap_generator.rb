# frozen_string_literal: true

class SitemapGenerator
  OUTPUT_FILES = %w[site-sitemap.xml sitemap.xml].freeze

  def self.refresh!
    previous_options = Rails.application.routes.default_url_options.dup
    Rails.application.routes.default_url_options.merge!(
      host: ENV.fetch("APP_HOST", "unknownforums.fun"),
      protocol: "https"
    )

    xml = ApplicationController.renderer.render(
      template: "sitemaps/show",
      formats: [ :xml ],
      layout: false,
      assigns: SitemapData.load
    )

    OUTPUT_FILES.each do |filename|
      path = Rails.public_path.join(filename)
      File.write(path, xml)
    end
  ensure
    Rails.application.routes.default_url_options.replace(previous_options) if previous_options
  end
end
