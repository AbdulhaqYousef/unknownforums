class CreateAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :attachments do |t|
      t.references :attachable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.integer :download_count, default: 0, null: false
      t.boolean :is_video, default: false, null: false
      t.integer :duration_seconds
      t.timestamps
    end

    add_index :attachments, %i[attachable_type attachable_id]
  end
end
