class AddColumnStatusEventCodeToPlayerRaceResults < ActiveRecord::Migration[6.1]
  def change
    add_column :player_race_results, :daily_status, :integer, after: :hold_daily
    add_column :player_race_results, :race_status, :integer, after: :race_no
    add_column :player_race_results, :event_code, :string, after: :time
  end
end
