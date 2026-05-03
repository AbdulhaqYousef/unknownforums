class CreateAttackEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :attack_events do |t|
      t.string   :ip_address,  null: false
      t.string   :matched,     null: false
      t.string   :path
      t.string   :user_agent
      t.datetime :occurred_at, null: false
    end
    add_index :attack_events, :occurred_at
    add_index :attack_events, :ip_address
  end
end
