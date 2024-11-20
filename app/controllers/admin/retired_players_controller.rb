# frozen_string_literal: true

module Admin
  # 引退選手コントローラ
  class RetiredPlayersController < ApplicationController
    before_action :snakeize_params
    def create
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.retired_players.params_blank') if params[:player_id].blank?

      player = Player.find_by(id: params[:player_id])
      raise CustomError.new(http_status: :not_found), I18n.t('custom_errors.retired_players.target_player_blank') unless player
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.retired_players.already_retired') if RetiredPlayer.find_by(player_id: player.id)

      RetiredPlayer.create!(player_id: player.id, retired_at: Time.zone.now)
      head :ok
    end

    def destroy
      retired_player = RetiredPlayer.find(params[:id])

      retired_player.destroy!
      head :ok
    end
  end
end
