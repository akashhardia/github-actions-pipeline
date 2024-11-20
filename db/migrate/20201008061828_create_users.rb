class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.integer :sixgram_id, null: false
      t.string :qr_user_id
      t.boolean :email_verified, null: false, default: false
      t.string :email_auth_code
      t.datetime :email_auth_expired_at

      t.timestamps
    end
  end
end
