class AddColumnToPlayerRaceResults < ActiveRecord::Migration[6.1]
  def change
    add_column :player_race_results, :hold_id, :string, after: :time
    add_column :player_race_results, :entries_id, :string, after: :hold_id
  end
end
