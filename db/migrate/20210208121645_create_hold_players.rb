class CreateHoldPlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :hold_players do |t|
      t.references :hold, foreign_key: true
      t.references :player, foreign_key: true

      t.timestamps
    end
  end
end
