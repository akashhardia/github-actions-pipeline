class AddUniqIndexToUserSixgramId < ActiveRecord::Migration[6.1]
  def change
    add_index :users, :sixgram_id, unique: true
  end
end
