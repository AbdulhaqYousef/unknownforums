class AddAdminModerationFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :previous_usernames, :text, array: true, default: [], null: false
    add_column :users, :flagged, :boolean, default: false, null: false
    add_column :users, :flag_reason, :text
    add_column :users, :moderation_note, :text

    add_index :users, :previous_usernames, using: :gin
    add_index :users, :flagged
  end
end
