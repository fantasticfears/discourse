class AddOtpSecretKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_secret_key, :string
    add_column :users, :otp_secret_key_verified, :boolean, default: false, null: false
  end
end
