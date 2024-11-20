class CreateWordCodes < ActiveRecord::Migration[6.0]
  def change
    create_table :word_codes do |t|
      t.string :master_id, null: false
      t.string :identifier, null: false
      t.string :code

      t.timestamps
    end
    add_index :word_codes, :master_id, unique: true
  end
end
