class CreateBikeInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :bike_infos do |t|
      t.references :race_player, null: false, foreign_key: true
      t.string :frame_code

      t.timestamps
      end
  end
end
