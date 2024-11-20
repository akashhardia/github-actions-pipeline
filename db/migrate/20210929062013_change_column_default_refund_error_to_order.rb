class ChangeColumnDefaultRefundErrorToOrder < ActiveRecord::Migration[6.1]
  def change
    change_column_default :orders, :refund_error, from: nil, to: false
  end
end
