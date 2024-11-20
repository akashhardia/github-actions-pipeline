class CreateHoldDailySchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :hold_daily_schedules do |t|
      t.references :hold_daily, null: false, foreign_key: true
      t.integer :daily_no, null: false

      t.timestamps
    end
  end
end
