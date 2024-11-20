class CreateTicketReserves < ActiveRecord::Migration[6.0]
  def change
    create_table :ticket_reserves do |t|
      t.references :order, null: false, foreign_key: true
      t.references :ticket, foreign_key: true
      t.references :seat_type_option, foreign_key: true
      t.datetime :transfer_at
      t.integer :transfer_to_user_id
      t.integer :transfer_from_user_id

      t.timestamps
    end
  end
end
