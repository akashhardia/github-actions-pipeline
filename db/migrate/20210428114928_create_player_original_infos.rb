class CreatePlayerOriginalInfos < ActiveRecord::Migration[6.0]
  def change
    create_table :player_original_infos do |t|
      t.references :player, null: false, foreign_key: true
      t.string :last_name_jp
      t.string :first_name_jp
      t.string :last_name_en
      t.string :first_name_en
      t.integer :speed
      t.integer :stamina
      t.integer :power
      t.integer :technique
      t.integer :mental
      t.integer :growth
      t.integer :original_record
      t.integer :popular
      t.integer :experience
      t.integer :evaluation
      t.string :nickname
      t.string :comment
      t.string :season_best
      t.string :year_best
      t.string :round_best
      t.string :race_type
      t.string :major_title
      t.string :pist6_title
      t.text :free1
      t.text :free2
      t.text :free3
      t.text :free4
      t.text :free5
      t.text :free6
      t.text :free7
      t.text :free8

      t.timestamps
    end
  end
end
