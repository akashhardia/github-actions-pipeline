# frozen_string_literal: true

module Admin
  # 出走表詳細コントローラ
  class RacesController < ApplicationController
    before_action :set_race

    def show
      render json: @race, include: :race_detail, serializer: ::RaceShowSerializer, key_transform: :camel_lower
    end

    def race_players
      return render json: { status: :no_race_detail, racePlayers: [] } if @race.race_detail.blank?

      race_players = @race.race_detail.race_players.includes(bike_info: [:front_wheel_info, :rear_wheel_info])
      return render json: { status: :no_race_player, racePlayers: [] } if race_players.blank?

      serialized_race_players = ActiveModelSerializers::SerializableResource.new(race_players, each_serializer: RacePlayerSerializer, include: { bike_info: [:front_wheel_info, :rear_wheel_info] }, key_transform: :camel_lower)

      render json: { status: :ok, racePlayers: serialized_race_players }
    end

    def odds_info
      return render json: { status: :no_race_detail, oddsInfo: [] } if @race.race_detail.blank?

      odds_info = @race.race_detail.odds_infos.latest
      return render json: { status: :no_odds_info, oddsInfo: [] } if odds_info.blank?

      serialized_odds_info = ActiveModelSerializers::SerializableResource.new(odds_info, each_serializer: OddsInfoSerializer, include: { odds_lists: :odds_details }, key_transform: :camel_lower)

      render json: { status: :ok, oddsInfo: serialized_odds_info }
    end

    def payoff_info
      return render json: { status: :no_race_detail, payoffInfo: [] } if @race.race_detail.blank?

      serialized_payoff_info = ActiveModelSerializers::SerializableResource.new(@race.race_detail, each_serializer: RaceDetailSerializer, include: [:payoff_lists, :ranks], key_transform: :camel_lower)

      render json: { status: :ok, payoffInfo: serialized_payoff_info }
    end

    def update_free_text
      @race.update!(free_text: params[:freeText])

      render json: @race, include: :race_detail, serializer: ::RaceShowSerializer, key_transform: :camel_lower
    end

    private

    def set_race
      @race = Race.find(params[:id])
    end

    def ranks_to_hash(ranks)
      ranks_hash = Hash.new { |value, key| value[key] = [] }
      ranks.map { |rank| ranks_hash["tip#{rank.arrival_order}"].push(rank.car_number) }
      ranks_hash
    end
  end
end
