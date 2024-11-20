class AddColumnsToWordCode < ActiveRecord::Migration[6.1]
  def change
    add_column :word_codes, :name1, :string, after: :code
    add_column :word_codes, :name2, :string, after: :name1
    add_column :word_codes, :name3, :string, after: :name2
  end
end
