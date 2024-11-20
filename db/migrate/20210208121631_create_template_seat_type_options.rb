class CreateTemplateSeatTypeOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :template_seat_type_options do |t|
      t.references :template_seat_type, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :price, null: false
      t.boolean :companion, null: false, default: false

      t.timestamps
    end
  end
end
