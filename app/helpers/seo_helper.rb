module SeoHelper
  def meta_description(text)
    content_for(:meta_description, truncate(strip_tags(text.to_s), length: 160, omission: "..."))
  end

  def meta_keywords(words)
    content_for(:meta_keywords, Array(words).join(", "))
  end

  def og_title(text)
    content_for(:og_title, text)
  end

  def og_description(text)
    content_for(:og_description, truncate(strip_tags(text.to_s), length: 200, omission: "..."))
  end

  def og_type(type)
    content_for(:og_type, type)
  end

  def og_image(url)
    content_for(:og_image, url)
  end

  def canonical_url(url)
    content_for(:canonical_url, url)
  end

  def noindex_page
    content_for(:robots, "noindex, nofollow")
  end

  def seo_homepage!
    content_for(:seo_homepage, true)
  end

  def forum_name
    ENV.fetch("FORUM_NAME", "Unknown Forums")
  end

  def forum_tagline
    ENV.fetch("FORUM_TAGLINE", "Community Discussion Forum & Downloads")
  end

  def forum_description
    ENV.fetch(
      "FORUM_DESCRIPTION",
      "Unknown Forums is a community discussion forum with threads, file sharing, and downloads. Join Unknown Forums to talk, share, and discover."
    )
  end

  def forum_site_url
    "https://#{ENV.fetch('APP_HOST', 'unknownforums.fun')}"
  end

  def default_meta_keywords
    [forum_name, "unknown forums", "unknownforums", "forum", "community", "discussion", "downloads", "file sharing"]
  end

  def seo_page_title
    if content_for?(:seo_homepage)
      "#{forum_name} — #{forum_tagline}"
    elsif content_for?(:title).present?
      "#{content_for(:title)} — #{forum_name}"
    else
      forum_name
    end
  end

  def seo_og_title
    content_for(:og_title).presence || (content_for?(:seo_homepage) ? seo_page_title : content_for(:title).presence || forum_name)
  end

  def breadcrumb_jsonld(items)
    list_items = items.each_with_index.map do |item, i|
      {
        "@type" => "ListItem",
        "position" => i + 1,
        "name" => item[:name],
        "item" => item[:url]
      }.compact
    end

    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => list_items
    }.to_json.html_safe
  end

  def thread_seo_description(thread, posts, attachments: [])
    first_post = posts.first
    parts = ["#{thread.title} — discussion in #{thread.subforum.name} on #{forum_name}."]
    parts << truncate(strip_tags(first_post.body.to_s), length: 100, omission: "...") if first_post
    if attachments.any?
      names = attachments.first(3).map(&:filename).join(", ")
      parts << "Downloads: #{names}."
    end
    parts.join(" ")
  end

  def thread_seo_keywords(thread, attachments: [], tags: [])
    [
      thread.title,
      thread.subforum.name,
      thread.subforum.category.name,
      thread.user.username,
      *attachments.map(&:filename),
      *tags,
      "forum",
      "thread",
      "download"
    ].compact.uniq
  end

  def attachment_seo_description(attachment, thread: nil)
    parts = ["Download #{attachment.filename} from #{forum_name}."]
    parts << "Shared in #{thread.title}." if thread
    parts << "#{attachment.download_count} downloads." if attachment.download_count.positive?
    tag_list = attachment.file_tags.map(&:tag)
    parts << "Tags: #{tag_list.join(', ')}." if tag_list.any?
    parts.join(" ")
  end

  def attachment_seo_keywords(attachment, thread: nil)
    keywords = [attachment.filename, attachment.user.username, "download", "file"]
    keywords << thread.title if thread
    keywords.concat(attachment.file_tags.map(&:tag))
    keywords.concat([thread.subforum.name, thread.subforum.category.name]) if thread
    keywords.compact.uniq
  end

  def attachment_jsonld(attachment, thread: nil)
    data = {
      "@context" => "https://schema.org",
      "@type" => "DigitalDocument",
      "name" => attachment.filename,
      "url" => attachment_url(attachment),
      "description" => attachment_seo_description(attachment, thread: thread),
      "author" => {
        "@type" => "Person",
        "name" => attachment.user.username,
        "url" => user_url(attachment.user)
      },
      "datePublished" => attachment.created_at.iso8601,
      "encodingFormat" => attachment.content_type,
      "contentSize" => attachment.byte_size.to_s
    }
    if thread
      data[:isPartOf] = {
        "@type" => "DiscussionForumPosting",
        "name" => thread.title,
        "url" => forum_thread_url(thread)
      }
    end
    data.to_json.html_safe
  end

  def discussion_jsonld(thread, posts)
    first_post = posts.first
    {
      "@context" => "https://schema.org",
      "@type" => "DiscussionForumPosting",
      "headline" => thread.title,
      "url" => forum_thread_url(thread),
      "datePublished" => thread.created_at.iso8601,
      "dateModified" => thread.updated_at.iso8601,
      "author" => {
        "@type" => "Person",
        "name" => thread.user.username,
        "url" => user_url(thread.user)
      },
      "text" => first_post ? truncate(strip_tags(first_post.body.to_s), length: 500) : "",
      "interactionStatistic" => [
        {
          "@type" => "InteractionCounter",
          "interactionType" => "https://schema.org/CommentAction",
          "userInteractionCount" => thread.posts_count
        },
        {
          "@type" => "InteractionCounter",
          "interactionType" => "https://schema.org/ViewAction",
          "userInteractionCount" => thread.views_count
        }
      ],
      "comment" => Array(posts).first(5).map do |post|
        {
          "@type" => "Comment",
          "text" => truncate(strip_tags(post.body.to_s), length: 300),
          "datePublished" => post.created_at.iso8601,
          "author" => {
            "@type" => "Person",
            "name" => post.user.username
          }
        }
      end
    }.to_json.html_safe
  end

  def website_jsonld
    {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => forum_name,
      "alternateName" => ["UnknownForums", "unknown forums", "unknownforums.fun"],
      "description" => forum_description,
      "url" => root_url,
      "potentialAction" => {
        "@type" => "SearchAction",
        "target" => {
          "@type" => "EntryPoint",
          "urlTemplate" => "#{forum_site_url}/search?q={search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      }
    }.to_json.html_safe
  end

  def homepage_jsonld
    {
      "@context" => "https://schema.org",
      "@graph" => [
        {
          "@type" => "Organization",
          "@id" => "#{forum_site_url}/#organization",
          "name" => forum_name,
          "alternateName" => ["UnknownForums", "unknown forums", "unknownforums.fun"],
          "url" => forum_site_url,
          "description" => forum_description
        },
        {
          "@type" => "WebSite",
          "@id" => "#{forum_site_url}/#website",
          "url" => forum_site_url,
          "name" => forum_name,
          "alternateName" => ["UnknownForums", "unknown forums"],
          "description" => forum_description,
          "publisher" => { "@id" => "#{forum_site_url}/#organization" },
          "potentialAction" => {
            "@type" => "SearchAction",
            "target" => {
              "@type" => "EntryPoint",
              "urlTemplate" => "#{forum_site_url}/search?q={search_term_string}"
            },
            "query-input" => "required name=search_term_string"
          }
        }
      ]
    }.to_json.html_safe
  end
end
