class CreateExternalApiLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :external_api_logs do |t|
      t.string :host
      t.string :path
      t.text :request_params
      t.integer :response_http_status
      t.text :response_params

      t.timestamps
    end
  end
end
