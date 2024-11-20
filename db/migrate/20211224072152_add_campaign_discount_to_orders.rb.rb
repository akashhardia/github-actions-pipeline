class AddCampaignDiscountToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :campaign_discount, :integer
  end
end
