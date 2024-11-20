# frozen_string_literal: true

module V1
  module Mt
    # 選手要約情報
    class PlayerSummarySerializer < ApplicationSerializer
      attributes :id, :last_name_jp, :first_name_jp, :country_code

      delegate :last_name_jp, :first_name_jp, to: :player

      def id
        player.pf_250_regist_id
      end

      def country_code
        player.player_original_info&.free2
      end

      private

      def player
        object.player
      end
    end
  end
end
