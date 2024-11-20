class ChangeDatatypeSixgramId < ActiveRecord::Migration[6.0]
  def change
    change_column :users, :sixgram_id, :string
    change_column :visitor_profiles, :sixgram_id, :string
  end
end
