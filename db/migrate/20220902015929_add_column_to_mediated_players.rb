class AddColumnToMediatedPlayers < ActiveRecord::Migration[6.1]
  def change
    add_column :mediated_players, :pattern_code, :string, after: :entry_code
  end
end
