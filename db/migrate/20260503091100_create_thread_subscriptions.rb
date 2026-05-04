class CreateThreadSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :thread_subscriptions do |t|
      t.references :user,         null: false, foreign_key: true
      t.references :forum_thread, null: false, foreign_key: true
      t.datetime   :last_read_at
      t.timestamps
    end
    add_index :thread_subscriptions, [ :user_id, :forum_thread_id ], unique: true
  end
end
