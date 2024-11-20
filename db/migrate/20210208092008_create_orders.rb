class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :order_at, null: false
      t.integer :order_type, null: false
      t.integer :total_price, null: false
      t.references :seat_sale, foreign_key: true
      t.integer :status, null: false, default: 0
      t.references :user_coupon, foreign_key: true
      t.integer :option_discount, null: false, default: 0
      t.integer :coupon_discount, null: false, default: 0

      t.timestamps
    end
  end
end
