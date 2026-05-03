class AddIpToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :ip_address, :string
    add_index  :posts, :ip_address
  end
end
