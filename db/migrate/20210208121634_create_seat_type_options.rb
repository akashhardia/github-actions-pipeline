class CreateSeatTypeOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :seat_type_options do |t|
      t.references :seat_type, null: false, foreign_key: true
      t.references :template_seat_type_option, null: false, foreign_key: true

      t.timestamps
    end
  end
end
