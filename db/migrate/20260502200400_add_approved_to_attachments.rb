class AddApprovedToAttachments < ActiveRecord::Migration[8.1]
  def change
    add_column :attachments, :approved, :boolean, default: false, null: false
    add_index :attachments, :approved
  end
end
