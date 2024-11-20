class AddColumnsUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :unsubscribe_uuid, :string
    add_column :users, :unsubscribe_mail_sent_at, :datetime
  end
end
