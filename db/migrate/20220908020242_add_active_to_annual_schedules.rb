class AddActiveToAnnualSchedules < ActiveRecord::Migration[6.1]
  def change
    add_column :annual_schedules, :active, :boolean, default: false, null: false
  end
end
