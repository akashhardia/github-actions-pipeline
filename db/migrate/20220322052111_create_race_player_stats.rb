class CreateRacePlayerStats < ActiveRecord::Migration[6.1]
  def change
    create_table :race_player_stats do |t|
      t.references :race_player, null: false, foreign_key: true
      t.float :winner_rate, precision: 3, scale: 1
      t.float :second_quinella_rate, precision: 3, scale: 1
      t.float :third_quinella_rate, precision: 3, scale: 1

      t.timestamps
    end
  end
end
