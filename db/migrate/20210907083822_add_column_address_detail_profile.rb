class AddColumnAddressDetailProfile < ActiveRecord::Migration[6.1]
  def change
    add_column :profiles, :address_detail, :string
  end
end
