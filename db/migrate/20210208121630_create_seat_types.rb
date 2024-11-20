class CreateSeatTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :seat_types do |t|
      t.references :seat_sale, null: false, foreign_key: true
      t.references :master_seat_type, null: false, foreign_key: true
      t.references :template_seat_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
