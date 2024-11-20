class CreateCouponSeatTypeConditions < ActiveRecord::Migration[6.0]
  def change
    create_table :coupon_seat_type_conditions do |t|
      t.references :coupon, null: false, foreign_key: true
      t.references :master_seat_type, null: false, foreign_key: true

      t.timestamps
    end
    add_index :coupon_seat_type_conditions, [:coupon_id, :master_seat_type_id], unique: true, name: 'coupon_and_seat_type_index'
  end
end
