# frozen_string_literal: true

module V1
  module Mt
    # レース詳細情報
    class RaceDetailSerializer < ApplicationSerializer
      attributes :race_id, :time, :rank, :race_no, :event_code

      def race_id
        race_detail&.race_id
      end

      def rank # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        rank = object.rank.to_i >= 1 ? object.rank : nil
        unless rank
          code = race_detail&.race_result&.race_result_players&.detect { |a| a.pf_player_id == object.player.pf_player_id }&.result_event_codes&.order(:priority)&.first&.event_code
          rank = WordCode.find_by(identifier: 'V12', code: code)&.name1 if code.present?
        end

        rank.to_s
      end

      def event_code
        # event_code == "W", "X", "Y"（順位決定戦C,D,E）の場合はすべて"T"（順位決定戦）に変換
        return 'T' if %w[W X Y].include? race_detail&.race&.event_code

        race_detail&.race&.event_code
      end

      private

      def race_detail
        @race_detail ||= RaceDetail.find_by(entries_id: object.entries_id)
      end
    end
  end
end
