class CreateReputations < ActiveRecord::Migration[8.1]
  def change
    create_table :reputations do |t|
      t.references :giver, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.references :post, foreign_key: true
      t.integer :value, null: false
      t.text :comment
      t.timestamps
    end

    add_index :reputations, %i[giver_id receiver_id post_id], unique: true
  end
end
