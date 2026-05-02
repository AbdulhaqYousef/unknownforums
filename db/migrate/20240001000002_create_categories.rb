class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    add_index :categories, :position
  end
end
