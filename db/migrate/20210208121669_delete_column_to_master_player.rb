class DeleteColumnToMasterPlayer < ActiveRecord::Migration[6.0]
  def up
    remove_column :players, :power
    remove_column :players, :speed
    remove_column :players, :stamina
    remove_column :players, :technique
    remove_column :players, :mental
    remove_column :players, :recovery
  end

  def down
    add_column :players, :power, :decimal, precision: 4, scale: 1
    add_column :players, :speed, :decimal, precision: 4, scale: 1
    add_column :players, :stamina, :decimal, precision: 4, scale: 1
    add_column :players, :technique, :decimal, precision: 4, scale: 1
    add_column :players, :mental, :decimal, precision: 4, scale: 1
    add_column :players, :powrecoveryer, :decimal, precision: 4, scale: 1
  end
end
