class CreateTemplateSeatAreas < ActiveRecord::Migration[6.0]
  def change
    create_table :template_seat_areas do |t|
      t.references :master_seat_area, null: false, foreign_key: true
      t.references :template_seat_sale, null: false, foreign_key: true
      t.boolean :displayable, null: false, default: true

      t.timestamps
    end
  end
end
