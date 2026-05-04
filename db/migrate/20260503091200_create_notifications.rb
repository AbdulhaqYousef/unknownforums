class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor,     null: false, foreign_key: { to_table: :users }
      t.string     :kind,      null: false
      t.string     :notifiable_type
      t.bigint     :notifiable_id
      t.text       :message
      t.boolean    :read,      null: false, default: false
      t.timestamps
    end
    add_index :notifications, [ :recipient_id, :read ]
    add_index :notifications, [ :notifiable_type, :notifiable_id ]
  end
end
