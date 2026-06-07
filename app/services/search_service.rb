# frozen_string_literal: true

class SearchService
  SITE_SHORTCUTS = [
    {
      match: /\A(forumsunknown|unknownforums|unknown\s*forums|forums\s*unknown)\z/i,
      title: "UnknownForums",
      description: "Browse all categories and subforums",
      path_helper: :root_path
    },
    {
      match: /\Aforums\z/i,
      title: "Forum Home",
      description: "Categories and discussion boards",
      path_helper: :root_path
    },
    {
      match: /\Adownloads?\z/i,
      title: "Downloads",
      description: "Browse shared files from the community",
      path_helper: :downloads_path
    }
  ].freeze

  Result = Struct.new(:featured, :threads, :posts, :filters, keyword_init: true)

  attr_reader :query, :params, :user

  def initialize(query:, params: {}, user: nil)
    @query = query.to_s.strip
    @params = params
    @user = user
  end

  def call
    filters = normalized_filters

    return Result.new(featured: [], threads: ForumThread.none, posts: Post.none, filters: filters) if query.length < 2

    Result.new(
      featured: featured_shortcuts,
      threads: search_threads(filters),
      posts: search_posts(filters),
      filters: filters
    )
  end

  private

  def normalized_filters
    {
      subforum_id: params[:subforum_id].presence,
      author: params[:author].to_s.strip.presence,
      from: parse_date(params[:from]),
      to: parse_date(params[:to]),
      with_attachments: ActiveModel::Type::Boolean.new.cast(params[:with_attachments])
    }
  end

  def parse_date(value)
    return if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def featured_shortcuts
    normalized = query.downcase.gsub(/\s+/, " ")
    SITE_SHORTCUTS.filter_map do |shortcut|
      next unless shortcut[:match].match?(normalized)

      {
        title: shortcut[:title],
        description: shortcut[:description],
        url: Rails.application.routes.url_helpers.public_send(shortcut[:path_helper])
      }
    end
  end

  def tsquery
    @tsquery ||= query.split(/\s+/).filter_map do |word|
      cleaned = word.gsub(/[^\p{L}\p{N}_-]/u, "")
      next if cleaned.length < 2

      "#{cleaned}:*"
    end.join(" & ")
  end

  def search_threads(filters)
    return ForumThread.none if tsquery.blank?

    rank_expr = ActiveRecord::Base.sanitize_sql_array([
      "GREATEST(COALESCE(ts_rank(forum_threads.search_vector, to_tsquery('english', ?)), 0), similarity(forum_threads.title, ?), word_similarity(?, forum_threads.title))",
      tsquery, query, query
    ])

    scope = ForumThread.joins(:subforum, :user)
                       .where(
                         <<~SQL.squish,
                           forum_threads.search_vector @@ to_tsquery('english', ?)
                           OR similarity(forum_threads.title, ?) > 0.25
                           OR word_similarity(?, forum_threads.title) > 0.45
                         SQL
                         tsquery, query, query
                       )
                       .select(Arel.sql("forum_threads.*, (#{rank_expr}) AS rank"))
                       .order(Arel.sql("rank DESC"))
                       .limit(20)

    apply_thread_filters(scope, filters)
  end

  def search_posts(filters)
    return Post.none if tsquery.blank?

    rank_expr = ActiveRecord::Base.sanitize_sql_array([
      "GREATEST(COALESCE(ts_rank(posts.search_vector, to_tsquery('english', ?)), 0), similarity(posts.body, ?), word_similarity(?, posts.body))",
      tsquery, query, query
    ])

    scope = Post.visible
                .joins(:user, :thread)
                .where(
                  <<~SQL.squish,
                    posts.search_vector @@ to_tsquery('english', ?)
                    OR similarity(posts.body, ?) > 0.18
                    OR word_similarity(?, posts.body) > 0.35
                  SQL
                  tsquery, query, query
                )
                .select(Arel.sql("posts.*, (#{rank_expr}) AS rank"))
                .includes(:user, thread: :subforum)
                .order(Arel.sql("rank DESC"))
                .limit(20)

    apply_post_filters(scope, filters)
  end

  def apply_thread_filters(scope, filters)
    scope = scope.where(forum_threads: { subforum_id: readable_subforum_ids })
    scope = scope.where(forum_threads: { subforum_id: filters[:subforum_id] }) if filters[:subforum_id].present?
    scope = scope.where(users: { username: filters[:author] }) if filters[:author].present?
    scope = scope.where("forum_threads.created_at >= ?", filters[:from].beginning_of_day) if filters[:from]
    scope = scope.where("forum_threads.created_at <= ?", filters[:to].end_of_day) if filters[:to]
    scope
  end

  def apply_post_filters(scope, filters)
    scope = scope.where(forum_threads: { subforum_id: readable_subforum_ids })
    scope = scope.where(forum_threads: { subforum_id: filters[:subforum_id] }) if filters[:subforum_id].present?
    scope = scope.where(users: { username: filters[:author] }) if filters[:author].present?
    scope = scope.where("posts.created_at >= ?", filters[:from].beginning_of_day) if filters[:from]
    scope = scope.where("posts.created_at <= ?", filters[:to].end_of_day) if filters[:to]
    scope = scope.joins(:attachments).distinct if filters[:with_attachments]
    scope
  end

  def readable_subforum_ids
    @readable_subforum_ids ||= Subforum.readable_by(user).pluck(:id)
  end
end
