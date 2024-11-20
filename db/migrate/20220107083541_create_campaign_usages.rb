class CreateCampaignUsages < ActiveRecord::Migration[6.1]
  def change
    create_table :campaign_usages do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true

      t.timestamps
    end
  end
end
