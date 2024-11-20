class CreateMediatedPlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :mediated_players do |t|
      t.references :hold_player, foreign_key: true
      t.string :pf_player_id
      t.integer :regist_num
      t.string :issue_code
      t.string :grade_code
      t.string :repletion_code
      t.string :race_code
      t.string :first_race_code
      t.string :entry_code
      t.string :miss_day
      t.string :join_code
      t.string :change_code
      t.string :add_day
      t.string :add_issue_id
      t.string :add_issue_code

      t.timestamps
    end
  end
end
