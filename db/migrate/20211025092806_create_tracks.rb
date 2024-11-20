class CreateTracks < ActiveRecord::Migration[6.1]
  def change
    create_table :tracks do |t|
      t.string :track_code, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
