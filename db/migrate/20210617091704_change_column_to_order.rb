class ChangeColumnToOrder < ActiveRecord::Migration[6.1]
  def change
    remove_column :orders, :returned
    add_column :orders, :returned_at, :datetime
  end
end
