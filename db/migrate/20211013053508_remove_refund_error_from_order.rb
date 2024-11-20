class RemoveRefundErrorFromOrder < ActiveRecord::Migration[6.1]
  def up
    remove_column :orders, :refund_error, :boolean
  end

  def down
    add_column :orders, :refund_error, :boolean
  end
end
