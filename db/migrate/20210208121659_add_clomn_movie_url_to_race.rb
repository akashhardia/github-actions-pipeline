class AddClomnMovieUrlToRace < ActiveRecord::Migration[6.0]
  def change
    add_column :races, :race_movie_url, :string
    add_column :races, :interview_movie_url, :string
  end
end
