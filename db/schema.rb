# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_04_093600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attachments", force: :cascade do |t|
    t.boolean "approved", default: false, null: false
    t.bigint "attachable_id", null: false
    t.string "attachable_type", null: false
    t.bigint "byte_size", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.integer "download_count", default: 0, null: false
    t.integer "duration_seconds"
    t.string "filename", null: false
    t.boolean "is_video", default: false, null: false
    t.bigint "parent_attachment_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "version", default: 1, null: false
    t.jsonb "vt_report", default: {}
    t.string "vt_scan_id"
    t.datetime "vt_scanned_at"
    t.string "vt_status", default: "pending"
    t.index ["approved", "attachable_type", "download_count"], name: "idx_attachments_approved_type_downloads"
    t.index ["approved"], name: "index_attachments_on_approved"
    t.index ["attachable_type", "attachable_id", "approved"], name: "idx_attachments_attachable_approved"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable_type_and_attachable_id"
    t.index ["download_count"], name: "idx_attachments_download_count"
    t.index ["parent_attachment_id"], name: "index_attachments_on_parent_attachment_id"
    t.index ["user_id"], name: "idx_attachments_user_id"
    t.index ["user_id"], name: "index_attachments_on_user_id"
    t.index ["vt_status"], name: "index_attachments_on_vt_status"
  end

  create_table "attack_events", force: :cascade do |t|
    t.string "ip_address", null: false
    t.string "matched", null: false
    t.datetime "occurred_at", null: false
    t.string "path"
    t.string "user_agent"
    t.index ["ip_address"], name: "index_attack_events_on_ip_address"
    t.index ["occurred_at", "matched"], name: "idx_attack_events_occurred_matched"
    t.index ["occurred_at"], name: "index_attack_events_on_occurred_at"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
  end

  create_table "forum_threads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.boolean "locked", default: false, null: false
    t.boolean "pinned", default: false, null: false
    t.integer "posts_count", default: 0, null: false
    t.tsvector "search_vector"
    t.bigint "subforum_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["locked"], name: "index_forum_threads_on_locked"
    t.index ["search_vector"], name: "idx_threads_search", using: :gin
    t.index ["subforum_id", "pinned", "created_at"], name: "index_forum_threads_on_subforum_id_and_pinned_and_created_at"
    t.index ["subforum_id"], name: "index_forum_threads_on_subforum_id"
    t.index ["user_id"], name: "index_forum_threads_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.text "message"
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.boolean "read", default: false, null: false
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_id", "read"], name: "index_notifications_on_recipient_id_and_read"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "post_reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id", "user_id", "emoji"], name: "index_post_reactions_on_post_id_and_user_id_and_emoji", unique: true
    t.index ["post_id"], name: "index_post_reactions_on_post_id"
    t.index ["user_id"], name: "index_post_reactions_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.datetime "edited_at"
    t.bigint "forum_thread_id", null: false
    t.string "ip_address"
    t.bigint "quote_post_id"
    t.tsvector "search_vector"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted"], name: "index_posts_on_deleted"
    t.index ["forum_thread_id", "created_at"], name: "index_posts_on_forum_thread_id_and_created_at"
    t.index ["forum_thread_id", "deleted", "created_at"], name: "idx_posts_thread_visible_created"
    t.index ["ip_address"], name: "index_posts_on_ip_address"
    t.index ["quote_post_id"], name: "index_posts_on_quote_post_id"
    t.index ["search_vector"], name: "idx_posts_search", using: :gin
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "private_messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "read", default: false, null: false
    t.boolean "recipient_deleted", default: false, null: false
    t.bigint "recipient_id", null: false
    t.boolean "sender_deleted", default: false, null: false
    t.bigint "sender_id", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "read", "recipient_deleted"], name: "idx_pm_recipient_unread", where: "((read = false) AND (recipient_deleted = false))"
    t.index ["recipient_id", "read"], name: "index_private_messages_on_recipient_id_and_read"
    t.index ["recipient_id"], name: "index_private_messages_on_recipient_id"
    t.index ["sender_id"], name: "index_private_messages_on_sender_id"
  end

  create_table "reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "reason", null: false
    t.bigint "reportable_id", null: false
    t.string "reportable_type", null: false
    t.bigint "reporter_id", null: false
    t.bigint "resolved_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reportable_type_and_reportable_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_reports_on_resolved_by_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "reputations", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "giver_id", null: false
    t.bigint "post_id"
    t.bigint "receiver_id", null: false
    t.datetime "updated_at", null: false
    t.integer "value", null: false
    t.index ["giver_id", "receiver_id", "post_id"], name: "index_reputations_on_giver_id_and_receiver_id_and_post_id", unique: true
    t.index ["giver_id"], name: "index_reputations_on_giver_id"
    t.index ["post_id"], name: "index_reputations_on_post_id"
    t.index ["receiver_id"], name: "index_reputations_on_receiver_id"
  end

  create_table "site_pages", force: :cascade do |t|
    t.string "body_format", default: "html", null: false
    t.text "body_html", null: false
    t.datetime "created_at", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["slug"], name: "index_site_pages_on_slug", unique: true
    t.index ["updated_by_id"], name: "index_site_pages_on_updated_by_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "staff_notes", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["author_id"], name: "index_staff_notes_on_author_id"
    t.index ["user_id"], name: "index_staff_notes_on_user_id"
  end

  create_table "subforums", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "posts_count", default: 0, null: false
    t.integer "threads_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "position"], name: "index_subforums_on_category_id_and_position"
    t.index ["category_id"], name: "index_subforums_on_category_id"
    t.index ["position"], name: "index_subforums_on_position"
  end

  create_table "thread_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "forum_thread_id", null: false
    t.datetime "last_read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["forum_thread_id"], name: "index_thread_subscriptions_on_forum_thread_id"
    t.index ["user_id", "forum_thread_id"], name: "index_thread_subscriptions_on_user_id_and_forum_thread_id", unique: true
    t.index ["user_id"], name: "index_thread_subscriptions_on_user_id"
  end

  create_table "user_warnings", force: :cascade do |t|
    t.boolean "acknowledged", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "reason", null: false
    t.integer "severity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "warned_by_id", null: false
    t.index ["acknowledged"], name: "index_user_warnings_on_acknowledged"
    t.index ["user_id", "expires_at"], name: "idx_user_warnings_user_expires"
    t.index ["user_id"], name: "index_user_warnings_on_user_id"
    t.index ["warned_by_id"], name: "index_user_warnings_on_warned_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.boolean "banned", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "email_otp_attempts", default: 0, null: false
    t.string "email_otp_digest"
    t.datetime "email_otp_expires_at"
    t.string "email_otp_purpose"
    t.datetime "email_otp_sent_at"
    t.boolean "email_two_factor_enabled", default: false, null: false
    t.datetime "email_verified_at"
    t.integer "failed_login_attempts", default: 0, null: false
    t.text "flag_reason"
    t.boolean "flagged", default: false, null: false
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.datetime "last_seen_at"
    t.datetime "locked_until"
    t.text "moderation_note"
    t.string "password_digest", null: false
    t.integer "posts_count", default: 0, null: false
    t.text "previous_usernames", default: [], null: false, array: true
    t.integer "reputation", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.boolean "show_presence", default: true, null: false
    t.text "signature"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["banned"], name: "index_users_on_banned"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["email_otp_expires_at"], name: "index_users_on_email_otp_expires_at"
    t.index ["email_two_factor_enabled"], name: "index_users_on_email_two_factor_enabled"
    t.index ["email_verified_at"], name: "index_users_on_email_verified_at"
    t.index ["flagged"], name: "index_users_on_flagged"
    t.index ["last_seen_at"], name: "index_users_on_last_seen_at"
    t.index ["previous_usernames"], name: "index_users_on_previous_usernames", using: :gin
    t.index ["role"], name: "index_users_on_role"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "virus_total_quotas", force: :cascade do |t|
    t.integer "count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "period", null: false
    t.datetime "period_start", null: false
    t.datetime "updated_at", null: false
    t.index ["period", "period_start"], name: "index_virus_total_quotas_on_period_and_period_start", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attachments", "users"
  add_foreign_key "forum_threads", "subforums"
  add_foreign_key "forum_threads", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "post_reactions", "posts"
  add_foreign_key "post_reactions", "users"
  add_foreign_key "posts", "forum_threads"
  add_foreign_key "posts", "posts", column: "quote_post_id"
  add_foreign_key "posts", "users"
  add_foreign_key "private_messages", "users", column: "recipient_id"
  add_foreign_key "private_messages", "users", column: "sender_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "resolved_by_id"
  add_foreign_key "reputations", "posts"
  add_foreign_key "reputations", "users", column: "giver_id"
  add_foreign_key "reputations", "users", column: "receiver_id"
  add_foreign_key "site_pages", "users", column: "updated_by_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "staff_notes", "users"
  add_foreign_key "staff_notes", "users", column: "author_id"
  add_foreign_key "subforums", "categories"
  add_foreign_key "thread_subscriptions", "forum_threads"
  add_foreign_key "thread_subscriptions", "users"
  add_foreign_key "user_warnings", "users"
  add_foreign_key "user_warnings", "users", column: "warned_by_id"
end
