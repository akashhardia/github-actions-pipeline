# frozen_string_literal: true

module Admin
  # 開催コントローラ
  class HoldDailiesController < ApplicationController
    before_action :snakeize_params
    before_action :set_hold_daily, only: [:show, :movie_ids, :movie_ids_update]

    def index
      hold_dailies = Hold.find(params[:hold_id]).hold_dailies

      render json: hold_dailies, each_serializer: HoldDailyIndexSerializer, key_transform: :camel_lower
    end

    def calendar
      current = Time.zone.now
      base_date = Time.zone.local(params[:year] || current.year, params[:month] || current.month)
      hold_dailies = HoldDaily.includes(hold_daily_schedules: :seat_sales)
                              .where(event_date: base_date..base_date.end_of_month)
                              .where.not(seat_sales: { id: nil })

      render json: hold_dailies,
             each_serializer: HoldDailyIndexSerializer,
             include: { hold_daily_schedules: :seat_sales },
             relation: true,
             key_transform: :camel_lower
    end

    def show
      render json: @hold_daily, serializer: HoldDailySerializer, key_transform: :camel_lower
    end

    def movie_ids
      render json: @hold_daily.races.order(:race_no), each_serializer: RaceMovieIdSerializer, key_transform: :camel_lower
    end

    def movie_ids_update
      ActiveRecord::Base.transaction do
        params[:race_list].each do |race_movie_params|
          race = @hold_daily.races.includes(:hold_daily_schedule).find { |r| r.id == race_movie_params[:id].to_i }
          raise ActiveRecord: RecordNotFound if race.blank? # recordが見つからなかった場合はNotFound

          race.update!(race_movie_yt_id: race_movie_params[:race_movie_yt_id], interview_movie_yt_id: race_movie_params[:interview_movie_yt_id])
        end
      end

      head :ok
    end

    private

    def set_hold_daily
      @hold_daily = HoldDaily.find(params[:id])
    end
  end
end
