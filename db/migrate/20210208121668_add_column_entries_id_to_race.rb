class AddColumnEntriesIdToRace < ActiveRecord::Migration[6.0]
  def change
    add_column :races, :entries_id, :string
  end
end
