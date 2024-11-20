class AddIndexPlayerOriginalInfos < ActiveRecord::Migration[6.1]
  def change
    add_index(:player_original_infos, :pf_250_regist_id)
  end
end
