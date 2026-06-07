xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.tag! "urlset", "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do  # Homepage
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  # Downloads
  xml.url do
    xml.loc downloads_url
    xml.changefreq "daily"
    xml.priority "0.6"
  end

  # Static pages
  xml.url do
    xml.loc rules_url
    xml.changefreq "monthly"
    xml.priority "0.3"
  end
  xml.url do
    xml.loc terms_url
    xml.changefreq "monthly"
    xml.priority "0.3"
  end
  xml.url do
    xml.loc privacy_url
    xml.changefreq "monthly"
    xml.priority "0.3"
  end

  # Subforums
  @subforums.each do |subforum|
    xml.url do      xml.loc subforum_url(subforum)
      xml.changefreq "daily"
      xml.priority "0.8"
    end
  end

  # Threads
  @threads.each do |thread|
    xml.url do
      xml.loc forum_thread_url(thread)
      xml.lastmod thread.updated_at.iso8601
      xml.changefreq "weekly"
      xml.priority "0.7"
    end
  end

  # User profiles
  @users.each do |user|
    xml.url do
      xml.loc user_url(user)
      xml.lastmod user.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.4"
    end
  end

  # Public file pages
  @attachments.each do |attachment|
    xml.url do
      xml.loc attachment_url(attachment)
      xml.lastmod attachment.updated_at.iso8601
      xml.changefreq "monthly"
      xml.priority "0.6"
    end
  end
end
