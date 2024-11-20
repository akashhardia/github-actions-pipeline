class ChangeColumnToNotNullForPlayer < ActiveRecord::Migration[6.1]
  def change
    change_column_null :players, :player_class, true
    change_column_null :players, :regist_num, true
  end
end
