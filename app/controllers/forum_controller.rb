class ForumController < ApplicationController
  def index
    @categories = Category.includes(subforums: :category).order(:position, :name)

    subforum_ids = @categories.flat_map(&:subforums).map(&:id)
    @last_post_by_subforum = last_post_per_subforum(subforum_ids)

    @stats = {
      threads:   ForumThread.count,
      posts:     Post.where(deleted: false).count,
      members:   User.count,
      files:     Attachment.count,
      downloads: Attachment.sum(:download_count)
    }
  end

  private

  def last_post_per_subforum(subforum_ids)
    return {} if subforum_ids.empty?

    sql = <<~SQL
      SELECT DISTINCT ON (ft.subforum_id)
        ft.subforum_id,
        p.id          AS post_id,
        p.created_at  AS post_created_at,
        ft.id         AS thread_id,
        ft.title      AS thread_title,
        u.id          AS user_id,
        u.username    AS username
      FROM posts p
      JOIN forum_threads ft ON ft.id = p.forum_thread_id
      JOIN users u          ON u.id  = p.user_id
      WHERE ft.subforum_id = ANY(ARRAY[#{subforum_ids.join(',')}])
        AND p.deleted = false
      ORDER BY ft.subforum_id, p.created_at DESC
    SQL

    ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, h|
      h[row["subforum_id"].to_i] = row
    end
  end
end
