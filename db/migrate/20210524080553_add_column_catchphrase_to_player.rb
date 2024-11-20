class AddColumnCatchphraseToPlayer < ActiveRecord::Migration[6.1]
  def change
    add_column :players, :catchphrase, :string
  end
end
