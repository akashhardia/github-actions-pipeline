class CreateSeatSales < ActiveRecord::Migration[6.0]
  def change
    create_table :seat_sales do |t|
      t.references :template_seat_sale, foreign_key: true
      t.references :hold_daily_schedule, foreign_key: true
      t.integer :sales_status, null: false, default: 0
      t.datetime :sales_start_at, null: false
      t.datetime :sales_end_at, null: false
      t.datetime :admission_available_at, null: false
      t.datetime :admission_close_at, null: false
      t.datetime :force_sales_stop_at

      t.timestamps
    end
  end
end
