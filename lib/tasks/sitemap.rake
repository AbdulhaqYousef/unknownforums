# frozen_string_literal: true

namespace :sitemap do
  desc "Write static sitemap XML files to public/"
  task refresh: :environment do
    SitemapGenerator.refresh!
    puts "Wrote #{SitemapGenerator::OUTPUT_FILES.map { |file| Rails.public_path.join(file) }.join(', ')}"
  end
end
