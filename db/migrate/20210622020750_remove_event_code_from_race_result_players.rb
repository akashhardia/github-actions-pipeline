class RemoveEventCodeFromRaceResultPlayers < ActiveRecord::Migration[6.1]
  def up
    remove_column :race_result_players, :event_code1, :string
    remove_column :race_result_players, :event_code2, :string
    remove_column :race_result_players, :event_code3, :string
    remove_column :race_result_players, :event_code4, :string
    remove_column :race_result_players, :event_code5, :string
  end
  def down
    add_column :race_result_players, :event_code1, :string
    add_column :race_result_players, :event_code2, :string
    add_column :race_result_players, :event_code3, :string
    add_column :race_result_players, :event_code4, :string
    add_column :race_result_players, :event_code5, :string
  end
end
