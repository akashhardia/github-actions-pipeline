class CreateHoldPlayerResults < ActiveRecord::Migration[6.1]
  def change
    create_table :hold_player_results do |t|
      t.references :hold_player, null: false, foreign_key: true
      t.references :race_result_player, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
