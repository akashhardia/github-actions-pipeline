class RemoveAndAddColumnsToAnnualSchedules < ActiveRecord::Migration[6.1]
  def change
    remove_column :annual_schedules, :season, :string
    add_column :annual_schedules, :year_name, :string, after: :pre_day
    add_column :annual_schedules, :year_name_en, :string, after: :year_name
  end
end
