class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.text :reason, null: false
      t.integer :status, default: 0, null: false
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :reports, :status
    add_index :reports, %i[reportable_type reportable_id]
  end
end
