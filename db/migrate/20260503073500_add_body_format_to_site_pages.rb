class AddBodyFormatToSitePages < ActiveRecord::Migration[8.1]
  def change
    add_column :site_pages, :body_format, :string, default: "html", null: false
  end
end
