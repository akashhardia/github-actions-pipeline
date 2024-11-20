class DeletePfPlayerIdUniqnessFromPlayer < ActiveRecord::Migration[6.1]
  def change
    remove_index :players, :pf_player_id
    add_index :players, :pf_player_id
  end
end
