class ChangeDataOptionResponseParamsOfExternalApiLogs < ActiveRecord::Migration[6.1]
  def change
    change_column :external_api_logs, :response_params, :text, :limit => 4294967295
  end
end
