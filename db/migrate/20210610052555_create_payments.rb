class CreatePayments < ActiveRecord::Migration[6.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :charge_id, null: false
      t.integer :payment_progress, null: false, default: 0

      t.timestamps
    end
  end
end
