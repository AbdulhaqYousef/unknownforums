class CreateSubforums < ActiveRecord::Migration[8.1]
  def change
    create_table :subforums do |t|
      t.string :name, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.integer :threads_count, default: 0, null: false
      t.integer :posts_count, default: 0, null: false
      t.timestamps
    end

    add_index :subforums, :position
    add_index :subforums, %i[category_id position]
  end
end
