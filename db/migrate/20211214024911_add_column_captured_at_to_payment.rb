class AddColumnCapturedAtToPayment < ActiveRecord::Migration[6.1]
  def change
    add_column :payments, :captured_at, :datetime, after: :payment_progress
    add_column :payments, :refunded_at, :datetime, after: :captured_at
  end
end
