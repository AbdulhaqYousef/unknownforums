class AddEmailOtpFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_verified_at, :datetime
    add_column :users, :email_otp_digest, :string
    add_column :users, :email_otp_sent_at, :datetime
    add_column :users, :email_otp_expires_at, :datetime
    add_column :users, :email_otp_attempts, :integer, default: 0, null: false
    add_column :users, :email_otp_purpose, :string

    add_index :users, :email_verified_at
    add_index :users, :email_otp_expires_at
  end
end
