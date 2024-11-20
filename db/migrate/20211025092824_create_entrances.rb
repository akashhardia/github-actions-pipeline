class CreateEntrances < ActiveRecord::Migration[6.1]
  def change
    create_table :entrances do |t|
      t.references :track, null: false, foreign_key: true
      t.string :entrance_code, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
