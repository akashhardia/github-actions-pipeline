class AddEntranceIdToTemplateSeatAreas < ActiveRecord::Migration[6.1]
  def change
    add_reference :template_seat_areas, :entrance, foreign_key: true
  end
end
