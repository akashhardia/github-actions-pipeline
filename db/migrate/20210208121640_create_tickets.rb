class CreateTickets < ActiveRecord::Migration[6.0]
  def change
    create_table :tickets do |t|
      t.references :seat_area, null: false, foreign_key: true
      t.references :seat_type, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.references :master_seat_unit, foreign_key: true
      t.string :row, null: false
      t.integer :seat_number, null: false
      t.integer :status, null: false, default: 0
      t.integer :sales_type, null: false, default: 0
      t.string :transfer_uuid
      t.string :qr_ticket_id

      t.timestamps
    end
  end
end
