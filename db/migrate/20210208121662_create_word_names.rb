class CreateWordNames < ActiveRecord::Migration[6.0]
  def change
    create_table :word_names do |t|
      t.integer :word_code_id, null: false
      t.string :lang, null: false
      t.string :name
      t.string :abbreviation

      t.timestamps
    end
  end
end
