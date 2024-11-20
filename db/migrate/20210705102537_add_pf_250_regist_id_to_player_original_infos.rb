class AddPf250RegistIdToPlayerOriginalInfos < ActiveRecord::Migration[6.1]
  def change
    add_column :player_original_infos, :pf_250_regist_id, :string
  end
end
