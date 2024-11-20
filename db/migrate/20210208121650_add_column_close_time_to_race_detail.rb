class AddColumnCloseTimeToRaceDetail < ActiveRecord::Migration[6.0]
  def change
    add_column :race_details, :close_time, :datetime
  end
end
