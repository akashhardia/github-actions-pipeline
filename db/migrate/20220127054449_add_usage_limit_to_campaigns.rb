class AddUsageLimitToCampaigns < ActiveRecord::Migration[6.1]
  def change
    add_column :campaigns, :usage_limit, :integer, null: false, default: 9999999, after: :discount_rate
  end
end
