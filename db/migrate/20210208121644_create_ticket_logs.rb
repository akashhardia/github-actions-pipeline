class CreateTicketLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :ticket_logs do |t|
      t.references :ticket, foreign_key: true
      t.integer :log_type, null: false
      t.integer :request_status, null: false
      t.integer :status, null: false
      t.integer :result, null: false
      t.integer :face_recognition
      t.integer :result_status, null: false
      t.integer :failed_message

      t.timestamps
    end
  end
end
