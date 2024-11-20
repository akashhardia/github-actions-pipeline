class DropTablePayoffInfos < ActiveRecord::Migration[6.0]
  def change
    drop_table :payoff_infos do |t|
      t.references :race_detail, null: false, foreign_key: true
      t.string :entries_id
      t.integer :race_status

      t.timestamps
    end
  end
end
