class CreateOddsLists < ActiveRecord::Migration[6.0]
  def change
    create_table :odds_lists do |t|
      t.references :odds_info, null: false, foreign_key: true
      t.integer :vote_type, null: false
      t.integer :odds_count

      t.timestamps
    end
  end
end
