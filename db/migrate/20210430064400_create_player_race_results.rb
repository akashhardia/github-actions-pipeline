class CreatePlayerRaceResults < ActiveRecord::Migration[6.0]
  def change
    create_table :player_race_results do |t|
      t.references :player, null: false, foreign_key: true
      t.date :event_date
      t.integer :hold_daily
      t.integer :race_no
      t.integer :rank
      t.string :time

      t.timestamps
    end
  end
end
