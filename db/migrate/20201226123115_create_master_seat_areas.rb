class CreateMasterSeatAreas < ActiveRecord::Migration[6.0]
  def change
    create_table :master_seat_areas do |t|
      t.string :area, null: false
      t.string :position, null: false

      t.timestamps
    end
  end
end
