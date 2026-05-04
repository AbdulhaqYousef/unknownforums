class CreateCategoryModerators < ActiveRecord::Migration[8.1]
  def change
    create_table :category_moderators do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end

    add_index :category_moderators, [ :user_id, :category_id ], unique: true
  end
end
