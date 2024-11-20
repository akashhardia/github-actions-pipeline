class CreateTemplateSeatSales < ActiveRecord::Migration[6.0]
  def change
    create_table :template_seat_sales do |t|
      t.string :title, null: false
      t.string :description
      t.integer :status, null: false, default: 0
      t.boolean :immutable, null: false, default: false

      t.timestamps
    end
  end
end
