class AddIndexHoldRaceResultPlayers < ActiveRecord::Migration[6.1]
  def change
    add_index :holds, :hold_status
    add_index :race_result_players, :rank
    add_index :race_result_players, :pf_player_id
  end
end
