class CreateOddsDetails < ActiveRecord::Migration[6.0]
  def change
    create_table :odds_details do |t|
      t.references :odds_list, null: false, foreign_key: true
      t.string :tip1, null: false
      t.string :tip2
      t.string :tip3
      t.decimal :odds_val, null: false, precision: 6, scale: 1
      t.decimal :odds_max_val, precision: 6, scale: 1

      t.timestamps
    end
  end
end
