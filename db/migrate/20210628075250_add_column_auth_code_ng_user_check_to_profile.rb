class AddColumnAuthCodeNgUserCheckToProfile < ActiveRecord::Migration[6.1]
  def change
    add_column :profiles, :auth_code, :text
    add_column :profiles, :ng_user_check, :boolean, null: false, default: true
  end
end
 