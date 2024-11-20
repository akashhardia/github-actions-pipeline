class CreateRaceDetails < ActiveRecord::Migration[6.0]
  def change
    create_table :race_details do |t|
      t.references :race, null: false, foreign_key: true
      t.string :pf_hold_id, null: false
      t.integer :hold_id_daily, null: false
      t.string :track_code
      t.string :hold_day
      t.date :first_day
      t.integer :hold_daily
      t.integer :daily_branch
      t.string :entries_id, null: false
      t.string :bike_count
      t.integer :race_distance
      t.integer :laps_count
      t.string :post_time
      t.string :grade_code
      t.string :repletion_code
      t.string :race_code
      t.string :first_race_code
      t.string :entry_code
      t.string :type_code
      t.string :event_code
      t.string :details_code
      t.string :race_status

      t.timestamps
    end
  end
end
