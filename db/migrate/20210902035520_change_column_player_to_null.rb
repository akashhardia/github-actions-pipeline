class ChangeColumnPlayerToNull < ActiveRecord::Migration[6.1]
  def up
    change_column_null :players, :pf_player_id, true
  end

  def down
    change_column_null :players, :pf_player_id, false
  end
end
