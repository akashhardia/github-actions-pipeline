class AddColumnToRaceDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :hold_dailies, :first_half_race_count, :integer, after: :event_date
    add_column :races, :pattern_code, :string, after: :lap_count
    add_column :races, :time_zone_code, :integer, after: :race_no
    add_column :race_details, :pattern_code, :string, after: :laps_count
    add_column :race_details, :time_zone_code, :integer, after: :repletion_code
    add_column :time_trial_players, :entry_code, :string, after: :id
    add_column :time_trial_players, :first_race_code, :string, after: :id
    add_column :time_trial_players, :grade_code, :string, after: :gear
    add_column :time_trial_players, :pattern_code, :string, after: :updated_at
    add_column :time_trial_players, :race_code, :string, after: :ranking
    add_column :time_trial_players, :repletion_code, :string, after: :ranking
  end
end
