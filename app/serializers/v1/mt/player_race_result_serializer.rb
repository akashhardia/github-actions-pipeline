# frozen_string_literal: true

module V1
  module Mt
    # 選手戦績情報
    class PlayerRaceResultSerializer < ApplicationSerializer
      attributes :hold_id, :promoter_year, :first_day, :season, :tt_record, :tt_rank, :round_code, :race_list

      def promoter_year
        hold&.promoter_year
      end

      def first_day
        hold&.first_day
      end

      def season
        hold&.period
      end

      def tt_record
        tt_player&.total_time
      end

      def tt_rank
        tt_player&.ranking
      end

      def round_code
        hold&.round
      end

      def race_list
        race_list = @instance_options[:list][object.hold_id] || []
        ActiveModelSerializers::SerializableResource.new(race_list, each_serializer: V1::Mt::RaceDetailSerializer)
      end

      private

      def hold
        @hold ||= Hold.find_by(pf_hold_id: object.hold_id)
      end

      def tt_player
        @tt_player ||= hold&.time_trial_result&.time_trial_players&.find_by(pf_player_id: object.player.pf_player_id)
      end
    end
  end
end
