class CreateRacePlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :race_players do |t|
      t.references :race_detail, null: false, foreign_key: true
      t.integer :bracket_no
      t.integer :bike_no
      t.string :pf_player_id
      t.decimal :gear, precision: 3, scale: 2
      t.boolean :miss, null: false
      t.integer :start_position

      t.timestamps
      end
  end
end
