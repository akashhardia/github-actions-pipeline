class CreateRaceResults < ActiveRecord::Migration[6.0]
  def change
    create_table :race_results do |t|
      t.references :race_detail, null: false, foreign_key: true
      t.string :entries_id, null: false
      t.integer :bike_count
      t.string :race_stts
      t.string :post_time
      t.decimal :race_time, precision: 6, scale: 4
      t.decimal :last_lap, precision: 6, scale: 4

      t.timestamps
    end
  end
end
