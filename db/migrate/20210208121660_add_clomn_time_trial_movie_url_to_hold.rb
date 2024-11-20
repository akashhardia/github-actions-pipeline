class AddClomnTimeTrialMovieUrlToHold < ActiveRecord::Migration[6.0]
  def change
    add_column :holds, :time_trial_movie_url, :string
  end
end
