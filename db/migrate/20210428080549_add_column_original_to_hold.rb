class AddColumnOriginalToHold < ActiveRecord::Migration[6.0]
  def change
    add_column :holds, :season, :string
    add_column :holds, :period, :integer
    add_column :holds, :round, :integer
    add_column :holds, :girl, :boolean
    add_column :holds, :promoter, :string
    add_column :holds, :time_zone, :integer
    add_column :holds, :audience, :boolean
    add_column :holds, :title_jp, :string
    add_column :holds, :title_en, :string
  end
end
