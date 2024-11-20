class CreateOddsInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :odds_infos do |t|
      t.references :race_detail, null: false, foreign_key: true
      t.string :entries_id, null: false
      t.datetime :odds_time, null: false
      t.boolean :fixed, null: false

      t.timestamps
    end
  end
end
