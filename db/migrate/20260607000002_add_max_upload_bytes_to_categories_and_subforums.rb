class AddMaxUploadBytesToCategoriesAndSubforums < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :max_upload_bytes, :bigint
    add_column :subforums, :max_upload_bytes, :bigint
  end
end
