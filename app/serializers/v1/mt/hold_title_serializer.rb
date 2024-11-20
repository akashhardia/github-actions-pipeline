# frozen_string_literal: true

module V1
  module Mt
    # PIST6タイトル
    class HoldTitleSerializer < ApplicationSerializer
      attributes :promoter_year, :season, :round_code

      def promoter_year
        hold&.promoter_year
      end

      def season
        hold&.period
      end

      def round_code
        object.round
      end

      private

      def hold
        @hold ||= Hold.find_by(pf_hold_id: object.pf_hold_id)
      end
    end
  end
end
