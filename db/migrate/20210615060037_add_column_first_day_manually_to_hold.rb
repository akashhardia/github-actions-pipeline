class AddColumnFirstDayManuallyToHold < ActiveRecord::Migration[6.1]
  def change
    add_column :holds, :first_day_manually, :date
  end
end
