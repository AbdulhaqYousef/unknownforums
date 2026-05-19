class AddMissingPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Subforum page: ORDER BY pinned DESC, updated_at DESC
    add_index :forum_threads, [ :subforum_id, :pinned, :updated_at ],
              order: { pinned: :desc, updated_at: :desc },
              algorithm: :concurrently,
              if_not_exists: true,
              name: "idx_forum_threads_subforum_pinned_updated_at"

    # Leaderboard: ORDER BY posts_count DESC
    add_index :users, :posts_count,
              order: { posts_count: :desc },
              algorithm: :concurrently,
              if_not_exists: true,
              name: "idx_users_posts_count"

    # Leaderboard: ORDER BY reputation DESC
    add_index :users, :reputation,
              order: { reputation: :desc },
              algorithm: :concurrently,
              if_not_exists: true,
              name: "idx_users_reputation"

    # Notifications bell: unread count per recipient
    add_index :notifications, [ :recipient_id, :read, :created_at ],
              order: { created_at: :desc },
              algorithm: :concurrently,
              if_not_exists: true,
              name: "idx_notifications_recipient_unread_created"

    # Forum index: ForumThread.maximum(:updated_at) used as etag
    add_index :forum_threads, :updated_at,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "idx_forum_threads_updated_at"
  end
end
