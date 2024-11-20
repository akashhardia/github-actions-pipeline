class CreateTemplateSeats < ActiveRecord::Migration[6.0]
  def change
    create_table :template_seats do |t|
      t.references :master_seat, null: false, foreign_key: true
      t.references :template_seat_area, null: false, foreign_key: true
      t.references :template_seat_type, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
