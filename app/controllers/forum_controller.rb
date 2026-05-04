class ForumController < ApplicationController
  def index
    fresh_when(
      etag: [ "forum-index", current_user&.id || "guest" ],
      last_modified: ForumThread.maximum(:updated_at) || Time.current,
      public: !logged_in?
    )
    @categories = Category.includes(subforums: :category).order(:position, :name)

    subforum_ids = @categories.flat_map(&:subforums).map(&:id)
    # Cache last post info per subforum to avoid expensive query on every request
    @last_post_by_subforum = Rails.cache.fetch("forum/last_posts/#{subforum_ids.hash}", expires_in: 2.minutes) do
      last_post_per_subforum(subforum_ids)
    end

    @stats = Rails.cache.fetch("forum_stats", expires_in: 5.minutes) do
      {
        threads:   ForumThread.count,
        posts:     Post.where(deleted: false).count,
        members:   User.count,
        files:     Attachment.count,
        downloads: Attachment.sum(:download_count)
      }
    end
  end

  private

  def last_post_per_subforum(subforum_ids)
    return {} if subforum_ids.empty?

    Post
      .joins(:user, :thread)
      .where(forum_threads: { subforum_id: subforum_ids }, deleted: false)
      .select(Arel.sql(
        "DISTINCT ON (forum_threads.subforum_id) " \
        "forum_threads.subforum_id, posts.id AS post_id, posts.created_at AS post_created_at, " \
        "forum_threads.id AS thread_id, forum_threads.title AS thread_title, " \
        "users.id AS user_id, users.username"
      ))
      .order(Arel.sql("forum_threads.subforum_id, posts.created_at DESC"))
      .each_with_object({}) do |row, h|
        h[row.subforum_id] = {
          "subforum_id"    => row.subforum_id.to_s,
          "post_id"        => row.post_id.to_s,
          "post_created_at" => row.post_created_at,
          "thread_id"      => row.thread_id.to_s,
          "thread_title"   => row.thread_title,
          "user_id"        => row.user_id.to_s,
          "username"       => row.username
        }
      end
  end
end
