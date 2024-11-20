class CreateTimeTrialPlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :time_trial_players do |t|
      t.references :time_trial_result, null: false, foreign_key: true
      t.string :pf_player_id
      t.decimal :gear, precision: 3, scale: 2
      t.decimal :first_time, precision: 6, scale: 4
      t.decimal :second_time, precision: 6, scale: 4
      t.decimal :total_time, precision: 6, scale: 4
      t.integer :ranking

      t.timestamps
    end
  end
end
