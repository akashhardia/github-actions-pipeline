# frozen_string_literal: true

module V1
  module Mt
    # タイムトライアル出走選手(改訂版)
    class TimeTrialPlayerRevisionSerializer < ActiveModel::Serializer
      attributes :id, :total_time, :rank, :gear, :pf_250_regist_id, :country_code, :first_name_jp, :last_name_jp

      delegate :pf_250_regist_id, to: :player

      def total_time
        case object.total_time
        when 99.9999, 99.999
          nil
        else
          object.total_time&.to_f
        end
      end

      def rank
        object.ranking
      end

      def gear
        object.gear&.to_f
      end

      def first_name_jp
        player&.first_name_jp
      end

      def last_name_jp
        player&.last_name_jp
      end

      def country_code
        player&.player_original_info&.free2
      end

      private

      def player
        @player ||= Player.includes(:player_original_info).where.not(player_original_info: { pf_250_regist_id: nil }).find_by(pf_player_id: object.pf_player_id)
      end
    end
  end
end
