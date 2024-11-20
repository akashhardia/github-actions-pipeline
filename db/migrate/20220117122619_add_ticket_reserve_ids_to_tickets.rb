class AddTicketReserveIdsToTickets < ActiveRecord::Migration[6.1]
  def change
    add_column :tickets, :purchase_ticket_reserve_id, :bigint, index: true, after: :user_id
    add_column :tickets, :current_ticket_reserve_id, :bigint, index: true, after: :purchase_ticket_reserve_id

    add_foreign_key :tickets, :ticket_reserves, column: :purchase_ticket_reserve_id
    add_foreign_key :tickets, :ticket_reserves, column: :current_ticket_reserve_id
  end
end
