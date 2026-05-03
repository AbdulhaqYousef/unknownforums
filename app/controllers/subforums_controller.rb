class SubforumsController < ApplicationController
  def show
    @subforum = Subforum.includes(:category).find(params[:id])
    thread_ids = @subforum.forum_threads.pluck(:id)
    @last_post_by_thread = last_post_per_thread(thread_ids)

    @threads = @subforum.forum_threads
                        .includes(:user)
                        .order(pinned: :desc, updated_at: :desc)
                        .page(params[:page])
  end

  private

  def last_post_per_thread(thread_ids)
    return {} if thread_ids.empty?

    sql = <<~SQL
      SELECT DISTINCT ON (p.forum_thread_id)
        p.forum_thread_id,
        p.id         AS post_id,
        p.created_at AS post_created_at,
        u.id         AS user_id,
        u.username   AS username
      FROM posts p
      JOIN users u ON u.id = p.user_id
      WHERE p.forum_thread_id = ANY(ARRAY[#{thread_ids.join(',')}])
        AND p.deleted = false
      ORDER BY p.forum_thread_id, p.created_at DESC
    SQL

    ActiveRecord::Base.connection.select_all(sql).each_with_object({}) do |row, h|
      h[row["forum_thread_id"].to_i] = row
    end
  end
end
