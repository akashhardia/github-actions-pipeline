class CreateTimeTrialBikeInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :time_trial_bike_infos do |t|
      t.references :time_trial_player, null: false, foreign_key: true
      t.string :frame_code

      t.timestamps
    end
  end
end
