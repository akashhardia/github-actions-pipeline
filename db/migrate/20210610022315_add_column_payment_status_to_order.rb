class AddColumnPaymentStatusToOrder < ActiveRecord::Migration[6.1]
  def change
    remove_column :orders, :status
    add_column :orders, :returned, :boolean, default: false, null: false
  end
end
