class CreateRaceResultPlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :race_result_players do |t|
      t.references :race_result, null: false, foreign_key: true
      t.integer :bike_no
      t.string :pf_player_id
      t.integer :incoming
      t.integer :rank
      t.integer :point
      t.string :trick_code
      t.string :difference_code
      t.boolean :home_class
      t.boolean :back_class
      t.integer :start_position
      t.decimal :last_lap, precision: 6, scale: 4
      t.string :event_code1
      t.string :event_code2
      t.string :event_code3
      t.string :event_code4
      t.string :event_code5

      t.timestamps
    end
  end
end
