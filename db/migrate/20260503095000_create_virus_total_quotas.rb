class CreateVirusTotalQuotas < ActiveRecord::Migration[8.1]
  def change
    create_table :virus_total_quotas do |t|
      t.string :period, null: false
      t.datetime :period_start, null: false
      t.integer :count, default: 0, null: false
      t.timestamps

      t.index [ :period, :period_start ], unique: true
    end
  end
end
