class CreateCampaigns < ActiveRecord::Migration[6.1]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.string :code, null: false
      t.integer :discount_rate, null: false
      t.string :description
      t.datetime :start_at
      t.datetime :end_at
      t.datetime :approved_at
      t.datetime :terminated_at
      t.boolean :displayable, default: true

      t.timestamps
    end
    add_index :campaigns, [:code], unique: true
  end
end
