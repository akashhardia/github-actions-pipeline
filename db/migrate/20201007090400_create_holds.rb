class CreateHolds < ActiveRecord::Migration[6.0]
  def change
    create_table :holds do |t|
      t.string :pf_hold_id, null: false
      t.string :track_code, null: false
      t.date :first_day, null: false
      t.integer :hold_days, null: false
      t.string :grade_code, null: false
      t.string :purpose_code, null: false
      t.string :repletion_code
      t.string :hold_name_jp
      t.string :hold_name_en
      t.integer :hold_status
      t.string :promoter_code, null: false
      t.integer :promoter_year
      t.integer :promoter_times
      t.integer :promoter_section

      t.timestamps

      t.index ["pf_hold_id"], unique: true
    end
  end
end
