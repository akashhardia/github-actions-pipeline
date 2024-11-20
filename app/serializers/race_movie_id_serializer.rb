# frozen_string_literal: true

# レースの動画IDのためのSerializerモデル
class RaceMovieIdSerializer < ActiveModel::Serializer
  attributes :id, :race_no, :race_movie_yt_id, :interview_movie_yt_id
end
