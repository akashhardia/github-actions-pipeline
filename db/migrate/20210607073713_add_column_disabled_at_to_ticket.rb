class AddColumnDisabledAtToTicket < ActiveRecord::Migration[6.1]
  def change
    add_column :tickets, :admission_disabled_at, :datetime
  end
end
