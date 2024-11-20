class CreatePlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :players do |t|
      t.string :pf_player_id, null: false
      t.integer :regist_num, null: false
      t.integer :player_class, null: false
      t.date :regist_day
      t.date :delete_day
      t.date :keirin_regist
      t.date :keirin_update
      t.date :keirin_delete
      t.date :keirin_expiration
      t.date :middle_regist
      t.date :middle_update
      t.date :middle_delete
      t.date :middle_expiration
      t.string :name_jp
      t.string :name_en
      t.date :birthday
      t.integer :gender_code
      t.string :country_code
      t.string :area_code
      t.integer :graduate
      t.string :current_rank_code
      t.string :next_rank_code
      t.decimal :height, precision: 4, scale: 1
      t.decimal :weight, precision: 4, scale: 1
      t.decimal :chest, precision: 4, scale: 1
      t.decimal :thigh, precision: 4, scale: 1
      t.decimal :leftgrip, precision: 3, scale: 1
      t.decimal :rightgrip, precision: 3, scale: 1
      t.decimal :vital, precision: 5, scale: 1
      t.decimal :spine, precision: 5, scale: 1
      t.string :lap_200
      t.string :lap_400
      t.string :lap_1000
      t.decimal :max_speed, precision: 4, scale: 2
      t.decimal :dash, precision: 4, scale: 2
      t.decimal :duration, precision: 4, scale: 2
      t.decimal :power, precision: 4, scale: 1
      t.decimal :speed, precision: 4, scale: 1
      t.decimal :stamina, precision: 4, scale: 1
      t.decimal :technique, precision: 4, scale: 1
      t.decimal :mental, precision: 4, scale: 1
      t.decimal :recovery, precision: 4, scale: 1

      t.timestamps
    end
    add_index :players, :pf_player_id, unique: true
  end
end
