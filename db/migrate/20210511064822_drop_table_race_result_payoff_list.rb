class DropTableRaceResultPayoffList < ActiveRecord::Migration[6.0]
  def change
    drop_table :race_result_payoff_lists do |t|
      t.references :race_result, null: false, foreign_key: true
      t.integer :payoff_type
      t.integer :vote_type
      t.string :tip1, null: false
      t.string :tip2
      t.string :tip3
      t.integer :payoff

      t.timestamps
    end
  end
end
