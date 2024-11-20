class CreateSeatAreas < ActiveRecord::Migration[6.0]
  def change
    create_table :seat_areas do |t|
      t.references :seat_sale, null: false, foreign_key: true
      t.references :master_seat_area, null: false, foreign_key: true
      t.boolean :displayable, null: false, default: true

      t.timestamps
    end
  end
end
