class CreateTemplateSeatSaleSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :template_seat_sale_schedules do |t|
      t.references :template_seat_sale, null: false, foreign_key: true
      t.string :sales_end_time, null: false
      t.string :admission_available_time, null: false
      t.string :admission_close_time, null: false
      t.integer :target_hold_schedule, null: false

      t.timestamps
    end
  end
end
