class CreateTimeTrialResults < ActiveRecord::Migration[6.0]
  def change
    create_table :time_trial_results do |t|
      t.references :hold, null: false, foreign_key: true
      t.string :pf_hold_id, null: false
      t.string :result_code
      t.boolean :confirm

      t.timestamps
    end
  end
end
