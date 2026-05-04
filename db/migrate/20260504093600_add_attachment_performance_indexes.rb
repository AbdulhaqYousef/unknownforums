class AddAttachmentPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # For leaderboard top_uploaders query: Attachment.group(:user_id).count
    add_index :attachments, :user_id, name: "idx_attachments_user_id"

    # For leaderboard top_downloads query: Attachment.order(download_count: :desc)
    add_index :attachments, :download_count, name: "idx_attachments_download_count"

    # For combined approved + public downloads queries
    add_index :attachments, [ :approved, :attachable_type, :download_count ],
              name: "idx_attachments_approved_type_downloads"
  end
end
