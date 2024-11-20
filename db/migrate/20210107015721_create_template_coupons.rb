class CreateTemplateCoupons < ActiveRecord::Migration[6.0]
  def change
    create_table :template_coupons do |t|
      t.string :title, null: false
      t.integer :rate, null: false
      t.text :note

      t.timestamps
    end
  end
end
