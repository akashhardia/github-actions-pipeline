class AddNextAndPrevTicketReserveColumnsToTicketReserves < ActiveRecord::Migration[6.1]
  def change
    add_column :ticket_reserves, :next_ticket_reserve_id, :bigint, index: true, after: :transfer_from_user_id
    add_column :ticket_reserves, :previous_ticket_reserve_id, :bigint, index: true, after: :next_ticket_reserve_id

    add_foreign_key :ticket_reserves, :ticket_reserves, column: :next_ticket_reserve_id
    add_foreign_key :ticket_reserves, :ticket_reserves, column: :previous_ticket_reserve_id
  end
end
