class AddColumnToMasterSeatAreas < ActiveRecord::Migration[6.1]
  def change
    add_column :master_seat_areas, :sub_position, :string
    add_column :master_seat_areas, :sub_code, :string
  end
end
