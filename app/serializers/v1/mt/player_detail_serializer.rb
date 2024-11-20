# frozen_string_literal: true

module V1
  module Mt
    # 選手詳細情報
    class PlayerDetailSerializer < ApplicationSerializer
      attributes :id, :last_name_jp, :first_name_jp, :last_name_en, :first_name_en, :birthday, :height, :weight,
                 :country_code, :catchphrase, :speed, :stamina, :power, :technique, :catchphrase,
                 :mental, :evaluation, :year_best, :round_best, :major_title, :pist6_title,
                 :winner_rate, :first_count, :first_place_count, :second_place_count

      attribute :round_result_list

      delegate :speed, :stamina, :power, :technique, :mental,
               :evaluation, :year_best, :round_best,
               :major_title, :pist6_title, :winner_rate, to: :object

      def id
        object.player_original_info&.pf_250_regist_id
      end

      def round_result_list
        cache_key = self.class.name + '#' + __method__.to_s + "(#{object.pf_player_id})"
        RedisCache.new(Redis::Objects.redis).fetch(cache_key, self.class.method(:generate_round_result_list), object.pf_player_id)
      end

      def self.generate_round_result_list(pf_player_id)
        past_participation_hold(pf_player_id).each_with_object([]) do |hold, result|
          race_list = hold.races.includes([hold_daily_schedule: :hold_daily], [race_detail: [race_result: :race_result_players]])
                          .where(race_result_players: { pf_player_id: pf_player_id })
                          .filter_race_result_player_rank
                          .order('hold_dailies.hold_daily')
                          .order(:program_no)

          last_race = race_list.last
          tt_player = hold.time_trial_result&.time_trial_players&.detect { |a| a.pf_player_id == pf_player_id }
          result << round_result_molding(hold, last_race, tt_player, race_list, pf_player_id)
        end
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

      private

      def birthday_format(birthday)
        date_array = birthday.split('/')
        date_array.each_with_index do |d, idx|
          next if idx.zero?

          date_array[idx] = format('%02d', d.to_i)
        end.join('-')
      end

      class << self
        def past_participation_hold(pf_player_id)
          Hold.finished_held
              .includes(races: [race_detail: [race_result: :race_result_players]], time_trial_result: :time_trial_players)
              .where(race_result_players: { pf_player_id: pf_player_id })
              .filter_race_result_player_rank
              .order(first_day: :desc)
              .limit(2)
        end

        def race_list_molding(race_list, pf_player_id)
          race_list.limit(4).map do |race|
            {
              event_code: event_code(race),
              details_code: race.details_code,
              race_rank: race&.race_detail&.race_result&.race_result_players&.detect { |a| a.pf_player_id == pf_player_id }&.rank
            }
          end
        end

        def round_result_molding(hold, last_race, tt_player, race_list, pf_player_id)
          { promoter_year: hold.promoter_year,
            season: hold.period,
            round_code: hold.round,
            event_date: last_race&.hold_daily_schedule&.hold_daily&.event_date,
            tt_record: tt_player&.total_time,
            tt_rank: tt_player&.ranking,
            last_event_code: event_code(last_race),
            last_details_code: last_race&.details_code,
            last_race_rank: last_race&.race_detail&.race_result&.race_result_players&.detect { |a| a.pf_player_id == pf_player_id }&.rank,
            race_list: race_list_molding(race_list, pf_player_id) }
        end

        def event_code(race)
          # event_code == "W", "X", "Y"（順位決定戦C,D,E）の場合はすべて"T"（順位決定戦）に変換
          return 'T' if %w[W X Y].include? race&.event_code

          race&.event_code
        end
      end
    end
  end
end
