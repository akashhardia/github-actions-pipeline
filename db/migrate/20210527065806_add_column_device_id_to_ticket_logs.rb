class AddColumnDeviceIdToTicketLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :ticket_logs, :device_id, :string
  end
end
