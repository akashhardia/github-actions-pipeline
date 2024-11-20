class AddColumnAddressDetailVisitorProfile < ActiveRecord::Migration[6.1]
  def change
    add_column :visitor_profiles, :address_detail, :string
  end
end
