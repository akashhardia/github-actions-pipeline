class ChangeColumnFromResultCodeToPlayersToTimeTrialResult < ActiveRecord::Migration[6.0]
  def change
    remove_column :time_trial_results, :result_code, :string
    add_column :time_trial_results, :players, :integer
  end
end
