class CreateMasterSeats < ActiveRecord::Migration[6.0]
  def change
    create_table :master_seats do |t|
      t.references :master_seat_type, null: false, foreign_key: true
      t.references :master_seat_area, null: false, foreign_key: true
      t.references :master_seat_unit, foreign_key: true
      t.string :row, null: false
      t.integer :seat_number, null: false
      t.integer :sales_type, null: false

      t.timestamps
    end
  end
end
