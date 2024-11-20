class RenamePayoffInfoIdColumnToPayoffLists < ActiveRecord::Migration[6.0]
  def change
    rename_column :payoff_lists, :payoff_info_id, :race_detail_id
    remove_foreign_key :payoff_lists, :payoff_infos
    add_foreign_key :payoff_lists, :race_details
  end
end
