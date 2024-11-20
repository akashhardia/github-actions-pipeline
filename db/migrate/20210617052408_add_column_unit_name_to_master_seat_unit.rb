class AddColumnUnitNameToMasterSeatUnit < ActiveRecord::Migration[6.1]
  def change
    add_column :master_seat_units, :unit_name, :string
  end
end
