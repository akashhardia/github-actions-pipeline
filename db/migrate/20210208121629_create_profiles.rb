class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :family_name, null: false
      t.string :given_name, null: false
      t.string :family_name_kana, null: false
      t.string :given_name_kana, null: false
      t.date :birthday, null: false
      t.integer :zip_code
      t.string :prefecture
      t.string :city
      t.string :address_line
      t.string :email, null: false

      t.timestamps
    end
  end
end
