# frozen_string_literal: true

module Admin
  # 選手コントローラ
  class PlayersController < ApplicationController
    before_action :set_player, only: [:show, :result, :race_results]

    def index
      players = params[:pf_player_id] ? Player.where('pf_player_id like ?', "#{params[:pf_player_id]}%") : Player.all
      players = players.page(params[:page] || 1).per(10)
      pagination = resources_with_pagination(players)
      serialized_players = ActiveModelSerializers::SerializableResource.new(players, each_serializer: PlayerSerializer, action: :index, key_transform: :camel_lower)

      render json: { players: serialized_players, pagination: pagination }
    end

    def export_csv
      players = Player.all.includes(:player_original_info)
      render json: players, each_serializer: PlayerSerializer, action: :export_csv, key_transform: :camel_lower
    end

    def update
      ActiveRecord::Base.transaction do
        # 選手のキャッチコピー更新
        data = update_player_csv_read(params[:file])

        players = data[:csv_data].map do |csv|
          # sqlを走らせないために、arrayのfindを使用
          player = data[:target_players].find { |pl| pl.player_original_info.pf_250_regist_id == csv[0] }
          player.catchphrase = csv[3]
          player
        end
        Player.import! players, on_duplicate_key_update: [:catchphrase]
      end

      head :ok
    end

    def show
      # summaryがついている場合は、一覧くらいの情報しか必要がない
      return render json: @player, serializer: PlayerSerializer, action: :show, key_transform: :camel_lower if params[:summary]

      render json: @player, serializer: PlayerDetailSerializer, key_transform: :camel_lower
    end

    def result
      # player_resultがない場合は、エラー回避のため新しくplayer_resultをbuildする
      player_result = @player.player_result || @player.build_player_result
      render json: player_result, serializer: PlayerResultSerializer, key_transform: :camel_lower
    end

    def race_results
      render json: @player.player_race_results, each_serializer: PlayerRaceResultSerializer, key_transform: :camel_lower
    end

    private

    def set_player
      @player = Player.find(params[:id])
    end

    # csvファイルを読み込んで、選手のチェックをする
    def update_player_csv_read(file_params)
      begin
        csv_data = CSV.read(file_params, headers: true)
      rescue StandardError
        raise CustomError.new(http_status: :bad_request, code: 'csv_read_error'), I18n.t('custom_errors.players.csv_read_error')
      end
      # pf_player_idのみを取得する
      player_ids = csv_data.map { |c| c[0] }.uniq
      target_players = Player.includes(:player_original_info).where(player_original_info: { pf_250_regist_id: player_ids })
      raise CustomError.new(http_status: :bad_request, code: 'csv_read_error'), I18n.t('custom_errors.players.invalid_player_id') unless target_players.size == player_ids.size

      { csv_data: csv_data, target_players: target_players.to_a }
    end
  end
end
