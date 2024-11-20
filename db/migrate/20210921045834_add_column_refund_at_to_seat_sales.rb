class AddColumnRefundAtToSeatSales < ActiveRecord::Migration[6.1]
  def change
    add_column :seat_sales, :refund_at, :datetime
  end
end
