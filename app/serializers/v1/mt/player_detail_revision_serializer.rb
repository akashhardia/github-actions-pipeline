# frozen_string_literal: true

module V1
  module Mt
    # 選手詳細情報
    class PlayerDetailRevisionSerializer < ApplicationSerializer
      attributes :id, :last_name_jp, :first_name_jp, :last_name_en, :first_name_en, :birthday,
                 :height, :weight, :country_code, :catchphrase, :speed, :stamina, :power, :technique,
                 :mental, :evaluation, :round_best, :year_best, :major_title, :pist6_title, :winner_rate,
                 :second_quinella_rate, :third_quinella_rate, :entry_count, :first_place_count, :second_place_count,
                 :run_count, :first_count, :second_count, :third_count, :outside_count, :round_result, :hold_list, :race_result_list

      def id
        object.player_original_info&.pf_250_regist_id
      end

      def evaluation
        object.evaluation_range(object.evaluation)
      end

      def country_code
        object.player_original_info&.free2.presence
      end

      def catchphrase
        object.player_original_info&.nickname
      end

      def birthday
        date = object.player_original_info&.free3
        date.nil? ? nil : birthday_format(date)
      end

      def height
        data = object.player_original_info&.free4
        data.nil? ? nil : data.to_f
      end

      def weight
        data = object.player_original_info&.free5
        data.nil? ? nil : data.to_f
      end

      def round_result
        hold = past_participation_hold(object.pf_player_id)
        if hold.nil?
          { promoter_year: nil,
            season: nil,
            round_code: nil,
            event_date: nil,
            tt_record: nil,
            tt_rank: nil,
            last_event_code: nil,
            last_details_code: nil,
            last_race_rank: nil,
            race_list: [] }
        else
          race_list = hold.races.joins(hold_daily_schedule: :hold_daily, race_detail: :race_result_players)
                          .where(race_result_players: { pf_player_id: object.pf_player_id })
                          .where.not(race_result_players: { rank: [0, nil] })
                          .order('hold_dailies.hold_daily')
                          .order(:program_no)

          last_race = race_list.last
          tt_player = hold.time_trial_result&.time_trial_players&.detect { |a| a.pf_player_id == object.pf_player_id }
          round_result_data(hold, last_race, tt_player, race_list)
        end
      end

      def hold_list
        hold_list = object.player_result&.hold_titles || []
        ActiveModelSerializers::SerializableResource.new(hold_list, each_serializer: V1::Mt::HoldTitleSerializer)
      end

      def race_result_list
        race_results = object.player_race_results.select(:player_id, :hold_id).distinct
        race_result_list = object.player_race_results.group_by(&:hold_id)
        ActiveModelSerializers::SerializableResource.new(race_results, each_serializer: V1::Mt::PlayerRaceResultSerializer, list: race_result_list)
      end

      private

      def round_result_data(hold, last_race, tt_player, race_list)
        { promoter_year: hold.promoter_year,
          season: hold.period,
          round_code: hold.round,
          event_date: last_race&.hold_daily_schedule&.hold_daily&.event_date,
          tt_record: tt_player&.total_time,
          tt_rank: tt_player&.ranking,
          last_event_code: event_code(last_race),
          last_details_code: last_race&.details_code,
          last_race_rank: last_race&.race_detail&.race_result&.race_result_players&.detect { |a| a.pf_player_id == object.pf_player_id }&.rank,
          race_list: race_list_molding(race_list) }
      end

      def past_participation_hold(pf_player_id)
        Hold.includes(races: [race_detail: [race_result: :race_result_players]], time_trial_result: :time_trial_players)
            .where(race_result_players: { pf_player_id: pf_player_id }, hold_status: :finished_held)
            .where.not(race_result_players: { rank: [0, nil] })
            .order(first_day: :desc)
            .first
      end

      def birthday_format(birthday)
        date_array = birthday.split('/')
        date_array.each_with_index do |d, idx|
          next if idx.zero?

          date_array[idx] = format('%02d', d.to_i)
        end.join('-')
      end

      def race_list_molding(race_list)
        race_list.limit(4).map do |race|
          {
            event_code: event_code(race),
            details_code: race.details_code,
            race_rank: race&.race_detail&.race_result&.race_result_players&.detect { |a| a.pf_player_id == object.pf_player_id }&.rank
          }
        end
      end

      def event_code(race)
        # event_code == "W", "X", "Y"（順位決定戦C,D,E）の場合はすべて"T"（順位決定戦）に変換
        return 'T' if %w[W X Y].include? race&.event_code

        race&.event_code
      end
    end
  end
end
