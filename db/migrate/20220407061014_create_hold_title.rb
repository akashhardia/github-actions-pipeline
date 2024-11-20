class CreateHoldTitle < ActiveRecord::Migration[6.1]
  def change
    create_table :hold_titles do |t|
      t.references :player_result, null: false, foreign_key: true
      t.string :pf_hold_id
      t.integer :period
      t.integer :round

      t.timestamps
    end
  end
end
