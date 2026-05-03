class CreateUserWarnings < ActiveRecord::Migration[8.1]
  def change
    create_table :user_warnings do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :warned_by,  null: false, foreign_key: { to_table: :users }
      t.string  :reason,        null: false
      t.integer :severity,      null: false, default: 0
      t.boolean :acknowledged,  null: false, default: false
      t.datetime :expires_at
      t.timestamps
    end
    add_index :user_warnings, :acknowledged
  end
end
