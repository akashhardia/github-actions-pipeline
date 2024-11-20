class CreateUserCoupons < ActiveRecord::Migration[6.0]
  def change
    create_table :user_coupons do |t|
      t.references :coupon, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_coupons, [:coupon_id, :user_id], unique: true
  end
end
