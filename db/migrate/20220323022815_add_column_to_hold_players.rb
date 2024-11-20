class AddColumnToHoldPlayers < ActiveRecord::Migration[6.1]
  def change
    # last_ranked_hold_id: 着位が存在する開催のうち、直近の開催のID
    add_column :hold_players, :last_ranked_hold_player_id, :bigint, after: :hold_id
    add_index :hold_players, :last_ranked_hold_player_id
    add_foreign_key :hold_players, :hold_players, column: :last_ranked_hold_player_id
  end
end
