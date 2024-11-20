class CreateTimeTrialFrontWheelInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :time_trial_front_wheel_infos do |t|
      t.references :time_trial_bike_info, null: false, foreign_key: true
      t.string :wheel_code
      t.integer :rental_code

      t.timestamps
    end
  end
end
