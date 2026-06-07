# frozen_string_literal: true

class AddPublicReadToForums < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :public_read, :boolean, default: true, null: false
    add_column :subforums, :public_read, :boolean, default: true, null: false
  end
end
