class AddColumnsToOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :orders, :refund_error, :boolean
    add_column :orders, :refund_error_message, :string
  end
end
