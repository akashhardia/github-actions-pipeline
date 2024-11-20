class AddColumnToHoldPlayer < ActiveRecord::Migration[6.1]
  def change
    add_column :hold_players, :last_hold_player_id, :bigint, after: :hold_id
    add_index :hold_players, :last_hold_player_id
    add_foreign_key :hold_players, :hold_players, column: :last_hold_player_id
  end
end
