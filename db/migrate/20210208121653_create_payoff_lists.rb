class CreatePayoffLists < ActiveRecord::Migration[6.0]
  def change
    create_table :payoff_lists do |t|
      t.references :payoff_info, null: false, foreign_key: true
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
