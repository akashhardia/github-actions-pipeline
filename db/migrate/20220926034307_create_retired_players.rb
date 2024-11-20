class CreateRetiredPlayers < ActiveRecord::Migration[6.1]
  def change
    create_table :retired_players do |t|
      t.references :player, null: false, foreign_key: true, index: { unique: true }
      t.datetime :retired_at, null: false

      t.timestamps
    end
  end
end
