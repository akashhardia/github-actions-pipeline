class AddColumnToProfile < ActiveRecord::Migration[6.1]
  def change
    add_column :profiles, :phone_number, :string
  end
end
