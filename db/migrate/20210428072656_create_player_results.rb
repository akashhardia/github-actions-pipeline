class CreatePlayerResults < ActiveRecord::Migration[6.0]
  def change
    create_table :player_results do |t|
      t.references :player, foreign_key: true
      t.string :pf_player_id
      t.integer :entry_count
      t.integer :run_count
      t.integer :consecutive_count
      t.integer :first_count
      t.integer :second_count
      t.integer :third_count
      t.integer :outside_count
      t.integer :first_place_count
      t.integer :second_place_count
      t.integer :third_place_count
      t.float :winner_rate, precision: 3, scale: 1
      t.float :second_quinella_rate, precision: 3, scale: 1
      t.float :third_quinella_rate, precision: 3, scale: 1

      t.timestamps
    end
  end
end
