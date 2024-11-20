class ChangeAllowNullToMasterSeatArea < ActiveRecord::Migration[6.0]
  def change
    add_column :master_seat_areas, :area_code, :string, null: false
    rename_column :master_seat_areas, :area, :area_name
    change_column_null :master_seat_areas, :position, true
    change_column_null :master_seats, :row, true
    change_column_null :tickets, :row, true
  end
end
