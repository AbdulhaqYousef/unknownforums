class AddLevelsBadgesAndProfileGifs < ActiveRecord::Migration[8.0]
  def up
    change_table :users, bulk: true do |t|
      t.integer :experience_points, null: false, default: 0
      t.integer :level_override
    end

    create_table :badges do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :badges, :name, unique: true
    add_index :badges, :position

    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.references :awarded_by, foreign_key: { to_table: :users }
      t.datetime :awarded_at, null: false
      t.timestamps
    end
    add_index :user_badges, %i[user_id badge_id], unique: true

    say_with_time "Backfilling experience points from activity" do
      User.reset_column_information
      User.find_each do |user|
        days = [ ((Time.current - user.created_at) / 1.day).to_i, 0 ].max
        xp = user.posts_count * 5 + user.reputation * 3 + days
        user.update_column(:experience_points, xp)
      end
    end
  end

  def down
    drop_table :user_badges
    drop_table :badges
    change_table :users, bulk: true do |t|
      t.remove :experience_points
      t.remove :level_override
    end
  end
end
