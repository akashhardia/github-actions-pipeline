class CreateCampaignMasterSeatTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :campaign_master_seat_types do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :master_seat_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
