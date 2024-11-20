# frozen_string_literal: true

module Admin
  # 開催コントローラ
  class HoldsController < ApplicationController
    before_action :set_hold, only: [:show, :mediated_players, :detail, :tt_movie_yt_id, :tt_movie_yt_id_update]

    def index
      holds = if params[:date].present?
                Hold.where('first_day >= ?', params[:date])
              else
                Hold.all
              end

      render json: holds, each_serializer: ::HoldSerializer, key_transform: :camel_lower, action: :index
    end

    def show
      render json: @hold, serializer: HoldShowSerializer, key_transform: :camel_lower
    end

    def detail
      render json: @hold, serializer: HoldDetailSerializer, key_transform: :camel_lower
    end

    def mediated_players
      mediated_players = @hold.mediated_players.includes(hold_player: [player: :player_original_info]).page(params[:page] || 1).per(10)
      pagination = resources_with_pagination(mediated_players)
      serialized_mediated_players = ActiveModelSerializers::SerializableResource.new(mediated_players, each_serializer: MediatedPlayerSerializer, key_transform: :camel_lower)

      render json: { mediatedPlayers: serialized_mediated_players, pagination: pagination }
    end

    def tt_movie_yt_id
      render json: { ttMovieYtId: @hold.tt_movie_yt_id }
    end

    def tt_movie_yt_id_update
      @hold.update!(tt_movie_yt_id: params[:ttMovieYtId])

      head :ok
    end

    private

    def set_hold
      @hold = Hold.find(params[:id])
    end
  end
end
