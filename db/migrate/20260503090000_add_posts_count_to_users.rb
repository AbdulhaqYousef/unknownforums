class AddPostsCountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :posts_count, :integer, default: 0, null: false

    say_with_time "Backfilling posts_count" do
      execute <<~SQL
        UPDATE users
        SET posts_count = (
          SELECT COUNT(*) FROM posts
          WHERE posts.user_id = users.id
          AND posts.deleted = false
        )
      SQL
    end
  end

  def down
    remove_column :users, :posts_count
  end
end
