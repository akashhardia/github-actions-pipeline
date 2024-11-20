class ChangeDataZipcodeToVisitorProfile < ActiveRecord::Migration[6.0]
  def change
    change_column :visitor_profiles, :zip_code, :string
  end
end
