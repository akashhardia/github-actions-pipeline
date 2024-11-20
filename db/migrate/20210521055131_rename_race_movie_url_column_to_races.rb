class RenameRaceMovieUrlColumnToRaces < ActiveRecord::Migration[6.1]
  def change
    rename_column :races, :race_movie_url, :race_movie_yt_id
    rename_column :races, :interview_movie_url, :interview_movie_yt_id
    rename_column :holds, :time_trial_movie_url, :tt_movie_yt_id
  end
end
