class AddColumnRefundEndAtToSeatSale < ActiveRecord::Migration[6.1]
  def change
    add_column :seat_sales, :refund_end_at, :datetime
  end
end
