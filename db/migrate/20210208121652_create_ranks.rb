class CreateRanks < ActiveRecord::Migration[6.0]
  def change
    create_table :ranks do |t|
      t.references :payoff_info, null: false, foreign_key: true
      t.integer :car_number, null: false
      t.integer :arrival_order, null: false

      t.timestamps
    end
  end
end
