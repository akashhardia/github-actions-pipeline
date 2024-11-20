class CreateAnnualSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :annual_schedules do |t|
      t.string :pf_id, null: false
      t.date :first_day
      t.string :track_code
      t.integer :hold_days
      t.boolean :pre_day
      t.string :season
      t.integer :period
      t.integer :round
      t.boolean :girl
      t.integer :promoter_times
      t.integer :promoter_section
      t.integer :time_zone
      t.boolean :audience
      t.string :grade_code

      t.timestamps

      t.index ["pf_id"], unique: true
    end
  end
end
