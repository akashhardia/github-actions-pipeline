class RenamePayoffInfoIdColumnToRanks < ActiveRecord::Migration[6.0]
  def change
    rename_column :ranks, :payoff_info_id, :race_detail_id
    remove_foreign_key :ranks, :payoff_infos
    add_foreign_key :ranks, :race_details
  end
end
