class CreateCampaignHoldDailySchedules < ActiveRecord::Migration[6.1]
  def change
    create_table :campaign_hold_daily_schedules do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :hold_daily_schedule, null: false, foreign_key: true

      t.timestamps
    end
  end
end
