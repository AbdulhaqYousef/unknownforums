class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.text :body, null: false
      t.references :user, null: false, foreign_key: true
      t.references :forum_thread, null: false, foreign_key: true, index: false
      t.references :quote_post, foreign_key: { to_table: :posts }
      t.index %i[forum_thread_id created_at]
      t.boolean :deleted, default: false, null: false
      t.timestamps
    end

    add_index :posts, :deleted
  end
end
