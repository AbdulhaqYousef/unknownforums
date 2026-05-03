class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Posts: most queries filter by deleted + sort by created_at
    add_index :posts, [:forum_thread_id, :deleted, :created_at],
              name: "idx_posts_thread_visible_created"

    # Attachments: vt_status lookups
    add_index :attachments, [:attachable_type, :attachable_id, :approved],
              name: "idx_attachments_attachable_approved"

    # Users: last_seen_at used for online detection
    # Already exists, skip

    # Forum threads: subforum listing with pinned sort
    # Already exists index on subforum_id + pinned + created_at

    # Private messages: recipient unread count
    add_index :private_messages, [:recipient_id, :read, :recipient_deleted],
              name: "idx_pm_recipient_unread",
              where: "read = false AND recipient_deleted = false"

    # Attack events: cleanup queries
    add_index :attack_events, [:occurred_at, :matched],
              name: "idx_attack_events_occurred_matched"

    # User warnings: active warnings per user
    add_index :user_warnings, [:user_id, :expires_at],
              name: "idx_user_warnings_user_expires"
  end
end
