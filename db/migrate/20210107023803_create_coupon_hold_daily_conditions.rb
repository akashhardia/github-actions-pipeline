class CreateCouponHoldDailyConditions < ActiveRecord::Migration[6.0]
  def change
    create_table :coupon_hold_daily_conditions do |t|
      t.references :coupon, null: false, foreign_key: true
      t.references :hold_daily_schedule, null: false, foreign_key: true

      t.timestamps
    end
    add_index :coupon_hold_daily_conditions, [:coupon_id, :hold_daily_schedule_id], unique: true, name: 'coupon_and_hold_daily_index'
  end
end
