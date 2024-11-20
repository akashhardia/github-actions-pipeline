class AddBinaryToCodeInCampaignsrails < ActiveRecord::Migration[6.1]
  def up
    execute('ALTER TABLE campaigns MODIFY code varchar (255) BINARY NOT NULL;')
  end

  def down
    execute('ALTER TABLE campaigns MODIFY code varchar (255) NOT NULL;')
  end
end
