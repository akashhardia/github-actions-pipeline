class CreateTemplateSeatTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :template_seat_types do |t|
      t.references :master_seat_type, null: false, foreign_key: true
      t.references :template_seat_sale, null: false, foreign_key: true
      t.integer :price, null: false

      t.timestamps
    end
  end
end
