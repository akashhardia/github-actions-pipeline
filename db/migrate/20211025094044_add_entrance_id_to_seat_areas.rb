class AddEntranceIdToSeatAreas < ActiveRecord::Migration[6.1]
  def change
    add_reference :seat_areas, :entrance, foreign_key: true
  end
end
