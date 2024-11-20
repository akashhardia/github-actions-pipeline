class CreateResultEventCodes < ActiveRecord::Migration[6.1]
  def change
    create_table :result_event_codes do |t|
      t.references :race_result_player, null: false, foreign_key: true
      t.integer :priority, null: false
      t.string :event_code
      t.timestamps
    end
  end
end
