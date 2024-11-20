class CreateMasterSeatUnits < ActiveRecord::Migration[6.0]
  def change
    create_table :master_seat_units do |t|
      t.integer :seat_type

      t.timestamps
    end
  end
end
