class ChangeColumnDefaultNotNullToOrders < ActiveRecord::Migration[6.1]
  def change
    change_column_default :orders, :campaign_discount, from: nil, to: 0
    change_column_null :orders, :campaign_discount, false
  end
end
