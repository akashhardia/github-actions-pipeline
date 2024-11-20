class CreateHoldDailies < ActiveRecord::Migration[6.0]
  def change
    create_table :hold_dailies do |t|
      t.references :hold, null: false, foreign_key: true
      t.integer :hold_id_daily, null: false
      t.date :event_date, null: false
      t.integer :hold_daily, null: false
      t.integer :daily_branch, null: false
      t.integer :program_count
      t.integer :race_count, null: false
      t.integer :daily_status, null: false

      t.timestamps
    end
  end
end
