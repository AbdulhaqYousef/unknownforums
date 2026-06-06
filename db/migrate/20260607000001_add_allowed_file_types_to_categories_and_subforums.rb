class AddAllowedFileTypesToCategoriesAndSubforums < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :allowed_file_types, :text
    add_column :subforums, :allowed_file_types, :text
  end
end
