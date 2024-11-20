class ChangeDataZipcodeToProfile < ActiveRecord::Migration[6.0]
  def change
    change_column :profiles, :zip_code, :string
  end
end
