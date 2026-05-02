class CreatePrivateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :private_messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :subject, null: false
      t.text :body, null: false
      t.boolean :read, default: false, null: false
      t.boolean :sender_deleted, default: false, null: false
      t.boolean :recipient_deleted, default: false, null: false
      t.timestamps
    end

    add_index :private_messages, %i[recipient_id read]
  end
end
