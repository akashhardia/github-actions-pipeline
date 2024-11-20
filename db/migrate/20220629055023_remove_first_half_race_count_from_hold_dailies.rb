class RemoveFirstHalfRaceCountFromHoldDailies < ActiveRecord::Migration[6.1]
  def up
    remove_column :hold_dailies, :first_half_race_count, :integer
  end

  def down
    add_column :hold_dailies, :first_half_race_count, :integer
  end
end
