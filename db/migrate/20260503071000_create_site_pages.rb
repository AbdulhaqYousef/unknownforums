class CreateSitePages < ActiveRecord::Migration[8.1]
  def change
    create_table :site_pages do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.text :body_html, null: false
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :site_pages, :slug, unique: true
  end
end
