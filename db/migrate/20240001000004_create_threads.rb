class CreateThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_threads do |t|
      t.string :title, null: false
      t.references :user, null: false, foreign_key: true
      t.references :subforum, null: false, foreign_key: true
      t.integer :views_count, default: 0, null: false
      t.integer :posts_count, default: 0, null: false
      t.boolean :locked, default: false, null: false
      t.boolean :pinned, default: false, null: false
      t.timestamps
    end

    add_index :forum_threads, %i[subforum_id pinned created_at]
    add_index :forum_threads, :locked
  end
end
