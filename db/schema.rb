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

ActiveRecord::Schema[8.1].define(version: 2026_05_02_200400) do
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
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["approved"], name: "index_attachments_on_approved"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable_type_and_attachable_id"
    t.index ["user_id"], name: "index_attachments_on_user_id"
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
    t.boolean "locked", default: false, null: false
    t.boolean "pinned", default: false, null: false
    t.integer "posts_count", default: 0, null: false
    t.bigint "subforum_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["locked"], name: "index_forum_threads_on_locked"
    t.index ["subforum_id", "pinned", "created_at"], name: "index_forum_threads_on_subforum_id_and_pinned_and_created_at"
    t.index ["subforum_id"], name: "index_forum_threads_on_subforum_id"
    t.index ["user_id"], name: "index_forum_threads_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "forum_thread_id", null: false
    t.bigint "quote_post_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted"], name: "index_posts_on_deleted"
    t.index ["forum_thread_id", "created_at"], name: "index_posts_on_forum_thread_id_and_created_at"
    t.index ["quote_post_id"], name: "index_posts_on_quote_post_id"
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

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.boolean "banned", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "failed_login_attempts", default: 0, null: false
    t.text "flag_reason"
    t.boolean "flagged", default: false, null: false
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.datetime "locked_until"
    t.text "moderation_note"
    t.string "password_digest", null: false
    t.text "previous_usernames", default: [], null: false, array: true
    t.integer "reputation", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.text "signature"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["banned"], name: "index_users_on_banned"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["flagged"], name: "index_users_on_flagged"
    t.index ["previous_usernames"], name: "index_users_on_previous_usernames", using: :gin
    t.index ["role"], name: "index_users_on_role"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attachments", "users"
  add_foreign_key "forum_threads", "subforums"
  add_foreign_key "forum_threads", "users"
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
  add_foreign_key "subforums", "categories"
end
