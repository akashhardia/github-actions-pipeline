class AddColumnToAnnualSchedule < ActiveRecord::Migration[6.1]
  def change
    add_column :annual_schedules, :promoter_year, :integer
  end
end
