class CreateRaces < ActiveRecord::Migration[6.0]
  def change
    create_table :races do |t|
      t.references :hold_daily_schedule, null: false, foreign_key: true
      t.integer :program_no, null: false
      t.integer :race_no, null: false
      t.string :post_time
      t.integer :race_distance, null: false
      t.integer :lap_count, null: false
      t.string :race_code, null: false
      t.string :first_race_code
      t.string :entry_code
      t.string :type_code
      t.string :event_code
      t.string :details_code
      t.datetime :post_start_time, null: false

      t.timestamps
    end
  end
end
