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

  def forum_name
    ENV.fetch("FORUM_NAME", "UnknownForums")
  end

  def forum_description
    ENV.fetch("FORUM_DESCRIPTION", "UnknownForums — Community discussion forums")
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
      "comment" => posts.first(5).map do |post|
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
      "description" => forum_description,
      "url" => root_url,
      "potentialAction" => {
        "@type" => "SearchAction",
        "target" => "#{root_url}search?q={search_term_string}",
        "query-input" => "required name=search_term_string"
      }
    }.to_json.html_safe
  end
end
