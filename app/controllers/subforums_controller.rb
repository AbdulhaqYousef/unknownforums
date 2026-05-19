class SubforumsController < ApplicationController
  def show
    @subforum = Subforum.includes(:category).find(params[:id])

    @threads = @subforum.forum_threads
                        .includes(:user)
                        .order(pinned: :desc, updated_at: :desc)
                        .page(params[:page])

    thread_ids = @threads.pluck(:id)
    @last_post_by_thread = last_post_per_thread(thread_ids)

    if logged_in?
      @subscription_map = ThreadSubscription
        .where(user: current_user, forum_thread_id: thread_ids)
        .index_by(&:forum_thread_id)
    end
  end

  private

  def last_post_per_thread(thread_ids)
    return {} if thread_ids.empty?

    Post
      .joins(:user)
      .where(forum_thread_id: thread_ids, deleted: false)
      .select(Arel.sql(
        "DISTINCT ON (posts.forum_thread_id) " \
        "posts.forum_thread_id, posts.id AS post_id, posts.created_at AS post_created_at, " \
        "users.id AS user_id, users.username"
      ))
      .order(Arel.sql("posts.forum_thread_id, posts.created_at DESC"))
      .each_with_object({}) do |row, h|
        h[row.forum_thread_id] = {
          "forum_thread_id"  => row.forum_thread_id.to_s,
          "post_id"          => row.post_id.to_s,
          "post_created_at"  => row.post_created_at,
          "user_id"          => row.user_id.to_s,
          "username"         => row.username
        }
      end
  end
end
