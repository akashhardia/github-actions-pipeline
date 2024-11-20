# frozen_string_literal: true

module V1
  module Mt
    # MT用APIコントローラ
    class DatasController < ApplicationController
      before_action :set_final_holds, only: [:finalists]

      def promoter_years
        result = {}.tap do |obj|
          # 現在開催中のシーズン取得(開催初日が２日前より、先の日付。開催初日で昇順に並べfirstが対象)
          select_hold = Hold.filter_hold_with_season.select(:id, :season, :promoter_year, :period, :round, :first_day, :hold_days, :tt_movie_yt_id)
          current_season_hold = select_hold.current_or_future.order(:first_day).first
          # 現在開催中のシーズン取得ができなかった場合（開催初日降順のfirstを取得）
          current_season_hold ||= select_hold.order('first_day DESC').first

          # シーズンリスト作成
          promoter_year_list = Hold.filter_hold_with_season.distinct.pluck(:promoter_year).sort
          seasons = promoter_year_list.map do |promoter_year|
            hold = Hold.filter_hold_with_season.find_by(promoter_year: promoter_year)
            { promoter_year_title: hold.season,
              promoter_year: promoter_year }
          end

          # レスポンスパラメータ作成
          obj['data'] = { current_promoter_year_title: current_season_hold&.season,
                          current_promoter_year: current_season_hold&.promoter_year,
                          current_season: current_season_hold&.period,
                          promoter_year_list: seasons }
        end

        render json: result
      end

      def seat_sales
        result = {}.tap do |obj|
          seat_sales_list = []
          seat_sales = SeatSale.on_sale.includes(hold_daily_schedule: [{ hold_daily: :hold }, :races])
                               .where('hold_dailies.event_date >= ?', Time.zone.today)
                               .where('sales_start_at <= ? and sales_end_at > ?', Time.zone.now, Time.zone.now)

          # ソート
          seat_sales = seat_sales.sorted_with_event_date_daily_no

          seat_sales.map do |seat_sale|
            seat_sales_list << { id: seat_sale.id, hold_daily_schedule: ActiveModelSerializers::SerializableResource.new(seat_sale.hold_daily_schedule, serializer: V1::Mt::HoldDailyScheduleSerializer) }
          end
          obj['data'] = { select_time: Time.zone.now.strftime('%F %T%:z'), seat_sales_list: seat_sales_list }
        end
        render json: result
      end

      def finalists
        return render json: { data: nil } if @target_holds.blank?

        render json: { data: { promoter_year: params[:promoter_year]&.to_i || fiscal_year(Time.zone.now), final: promoter_year_finalist(201), spring: promoter_year_finalist(1), summer: promoter_year_finalist(2), autumn: promoter_year_finalist(3), winter: promoter_year_finalist(4) } }
      end

      def annual_schedules
        promoter_year = params[:promoter_year] || fiscal_year(Time.zone.now)
        annual_schedules = AnnualSchedule.mt_api_scope(promoter_year)

        annual_schedule_list = annual_schedules.map do |annual_schedule|
          cloned_annual_schedule = annual_schedule.clone

          annual_schedule.event_date = annual_schedule.first_day
          cloned_annual_schedule.event_date = annual_schedule.first_day + 1

          [annual_schedule, cloned_annual_schedule]
        end.flatten

        render json: { data: { schedule_list: ActiveModelSerializers::SerializableResource.new(annual_schedule_list, each_serializer: V1::Mt::AnnualScheduleSerializer) } }
      end

      def rounds
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.promoter_year_blank') if params[:promoter_year].blank?

        promoter_year = params[:promoter_year].to_i

        where_not_value = Hold.includes([:time_trial_result]).where.not(round: nil).where.not(period: nil).order(:first_day)

        hold_list = if params[:season].present?
                      where_not_value.where(promoter_year: promoter_year, period: params[:season])
                    else
                      where_not_value.where(promoter_year: promoter_year)
                    end

        render json: { data: { promoter_year: promoter_year, round_list: ActiveModelSerializers::SerializableResource.new(hold_list, each_serializer: V1::Mt::HoldRoundSerializer) } }
      end

      def mediated_players
        raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.datas.promoter_year_requires_season_and_round_code') unless valid_params?

        hold = params[:promoter_year] ? Hold.find_by(promoter_year: params[:promoter_year].to_i, period: params[:season], round: params[:round_code]) : current_season_hold

        return render json: { data: nil } if hold.blank?

        # 条件分岐でsqlを走らせないために、配列にして処理しています
        mediated_players_array = hold.mediated_players.active_pf_250_regist_id_and_full_name_en.to_a
        # あっせん選手のリスト作成
        player_hash_list = mediated_player_list(mediated_players_array)

        render json: { data: {
          hold_id: hold.id,
          promoter_year: params[:promoter_year]&.to_i || hold.promoter_year,
          season: params[:season] || hold.period,
          round_code: params[:round] || hold.round,
          hold_status: hold.mt_hold_status,
          first_day: hold.first_day,
          hold_days: hold.hold_days,
          player_list: pf_250_regist_id_arr(player_hash_list[:pf_250_regist_id_list]),
          cancelled_list: pf_250_regist_id_arr(player_hash_list[:cancelled_list]),
          additional_list: pf_250_regist_id_arr(player_hash_list[:additioal_list]),
          absence_list: full_name_arr(player_hash_list[:absence_list]),
          updated_at: mediated_players_array.max_by { |player| player.updated_at.to_i }&.updated_at.to_s # 開催にぶら下がっている、mediated_playerのupdated_at(一番大きい値)を返す
        } }
      end

      def mediated_players_revision
        raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.datas.promoter_year_requires_season_and_round_code') unless valid_params?

        hold = params[:promoter_year] ? Hold.find_by(promoter_year: params[:promoter_year].to_i, period: params[:season], round: params[:round_code]) : current_season_hold

        return render json: { data: nil } if hold.blank?

        # 条件分岐でsqlを走らせないために、配列にして処理しています
        mediated_players_array = hold.mediated_players.active_pf_250_regist_id_and_full_name_en.to_a
        # あっせん選手のリスト作成
        player_hash_list = mediated_player_list(mediated_players_array)

        render json: { data: {
          hold_id: hold.id,
          promoter_year: params[:promoter_year]&.to_i || hold.promoter_year,
          season: params[:season] || hold.period,
          round_code: params[:round] || hold.round,
          hold_status: hold.mt_hold_status,
          first_day: hold.first_day,
          hold_days: hold.hold_days,
          player_list: ActiveModelSerializers::SerializableResource.new(player_hash_list[:pf_250_regist_id_list], each_serializer: V1::Mt::PlayerSummarySerializer),
          cancelled_list: ActiveModelSerializers::SerializableResource.new(player_hash_list[:cancelled_list], each_serializer: V1::Mt::PlayerSummarySerializer),
          additional_list: ActiveModelSerializers::SerializableResource.new(player_hash_list[:additioal_list], each_serializer: V1::Mt::PlayerSummarySerializer),
          absence_list: ActiveModelSerializers::SerializableResource.new(player_hash_list[:absence_list], each_serializer: V1::Mt::PlayerSummarySerializer),
          updated_at: mediated_players_array.max_by { |player| player.updated_at.to_i }&.updated_at.to_s # 開催にぶら下がっている、mediated_playerのupdated_at(一番大きい値)を返す
        } }
      end

      def time_trial_results
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.promoter_year_requires_season_and_round_code') unless valid_params?

        hold = if params[:promoter_year]
                 Hold.find_by(promoter_year: params[:promoter_year], period: params[:season], round: params[:round_code])
               else
                 current_season_hold
               end
        return render json: { data: nil } if hold.blank?

        if hold.time_trial_result.present?
          time_trial_players = hold.time_trial_result.time_trial_players.order(:ranking)
          serialized_tt_results = ActiveModelSerializers::SerializableResource.new(time_trial_players, each_serializer: V1::Mt::TimeTrialPlayerSerializer)
        else
          serialized_tt_results = []
        end

        render json: { data: {
          promoter_year: hold.promoter_year,
          season: params[:season] || hold.period,
          round_code: params[:round] || hold.round,
          hold_id: hold.id,
          hold_status: hold.mt_hold_status,
          first_day: hold.first_day,
          hold_days: hold.hold_days,
          tt_movie_yt_id: hold.tt_movie_yt_id,
          tt_result_list: serialized_tt_results
        } }
      end

      def time_trial_results_revision
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.promoter_year_requires_season_and_round_code') unless valid_params?

        hold = if params[:promoter_year]
                 Hold.find_by(promoter_year: params[:promoter_year], period: params[:season], round: params[:round_code])
               else
                 current_season_hold
               end
        return render json: { data: nil } if hold.blank?

        if hold.time_trial_result.present?
          time_trial_players = hold.time_trial_result.time_trial_players.order(:ranking)
          serialized_tt_results = ActiveModelSerializers::SerializableResource.new(time_trial_players, each_serializer: V1::Mt::TimeTrialPlayerRevisionSerializer)
        else
          serialized_tt_results = []
        end

        render json: { data: {
          promoter_year: hold.promoter_year,
          season: params[:season] || hold.period,
          round_code: params[:round] || hold.round,
          hold_id: hold.id,
          hold_status: hold.mt_hold_status,
          first_day: hold.first_day,
          hold_days: hold.hold_days,
          tt_movie_yt_id: hold.tt_movie_yt_id,
          tt_result_list: serialized_tt_results
        } }
      end

      def races
        hold_daily_schedule_list = if params[:hold_daily_schedule_id_list].present?
                                     HoldDailySchedule.includes(:races, hold_daily: :hold).filter_races.filter_holds.where(id: params[:hold_daily_schedule_id_list])
                                   else
                                     find_hold_daily_schedule
                                   end
        result = hold_daily_schedule_list.each_with_object([]) do |hold_daily_schedule, arr|
          event_date = hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d')
          day_night = hold_daily_schedule.daily_no_before_type_cast
          race_list = hold_daily_schedule.races.map do |race|
            { id: race.id,
              race_no: race.race_no.to_i,
              event_date: event_date,
              day_night: day_night,
              post_time: time_format(race.post_time),
              name: race_name(race.event_code),
              detail: race.details_code,
              cancel_status: cancel_status(race),
              race_status: race_status(race),
              free_text: race.formated_free_text,
              player_list: ActiveModelSerializers::SerializableResource.new(player_list(race), each_serializer: V1::Mt::PlayerDetailSerializer) }
          end
          hold = hold_daily_schedule.hold_daily.hold

          arr << { promoter_year: hold.promoter_year, season: hold.period, round_code: hold.round, hold_daily_schedule: ActiveModelSerializers::SerializableResource.new(hold_daily_schedule, serializer: V1::Mt::HoldDailyScheduleSerializer), race_list: race_list }
        end

        render json: { data: result }
      end

      def races_revision
        hold_daily_schedule_list = if params[:hold_daily_schedule_id_list].present?
                                     HoldDailySchedule.includes(:races, hold_daily: :hold).filter_races.filter_holds.where(id: params[:hold_daily_schedule_id_list])
                                   else
                                     find_hold_daily_schedule
                                   end
        result = hold_daily_schedule_list.each_with_object([]) do |hold_daily_schedule, arr|
          event_date = hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d')
          day_night = hold_daily_schedule.daily_no_before_type_cast
          race_list = hold_daily_schedule.races.includes(race_detail: [:race_players, :race_result]).map do |race|
            { id: race.id,
              race_no: race.race_no.to_i,
              event_date: event_date,
              day_night: day_night,
              post_time: time_format(race.post_time),
              name: race_name(race.event_code),
              detail: race.details_code,
              cancel_status: cancel_status(race),
              race_status: race_status(race),
              player_list: ActiveModelSerializers::SerializableResource.new(player_list_with_bike_no(race), each_serializer: V1::Mt::PlayerListDetailSerializer) }
          end
          arr << { hold_daily_schedule: ActiveModelSerializers::SerializableResource.new(hold_daily_schedule, serializer: V1::Mt::HoldDailyScheduleSerializer), race_list: race_list }
        end

        render json: { data: result }
      end

      def hold_daily_schedules
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.promoter_year_requires_season_and_round_code') if params[:promoter_year].present? && (params[:season].blank? || params[:round_code].blank?)

        hold_daily_schedule_list = if params[:promoter_year]
                                     hold = Hold.find_by(promoter_year: params[:promoter_year].to_i, period: params[:season], round: params[:round_code])
                                     if hold.blank?
                                       []
                                     else
                                       hold.hold_daily_schedules.includes(:races, hold_daily: :hold)
                                           .where.not(races: { event_code: nil })
                                           .sorted_with_event_date_daily_no
                                     end
                                   else
                                     # 現在開催中および将来の開催情報を取得する
                                     current_or_future_holds = Hold.current_or_future
                                                                   .where.not(period: nil)
                                                                   .where.not(round: nil)
                                     HoldDailySchedule.includes({ hold_daily: :hold }, :races)
                                                      .where(hold: { id: current_or_future_holds.ids })
                                                      .where.not(races: { event_code: nil })
                                                      .sorted_with_event_date_daily_no
                                                      .select(&:before_and_being_held?)
                                   end

        serialized_hold_daily_schedules = ActiveModelSerializers::SerializableResource.new(hold_daily_schedule_list, each_serializer: V1::Mt::HoldDailyScheduleSerializer)

        render json: { data: { hold_daily_schedule_list: serialized_hold_daily_schedules } }
      end

      def player_detail
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.filter_key_requires_filter_value') if params[:filter_key].present? && params[:filter_value].blank?

        sort_key = params[:sort_key]
        filter_key = params[:filter_key]
        filter_value = params[:filter_value]
        limit = params[:limit].presence || 20
        offset = params[:offset]
        pf_250_regist_ids = params[:players]

        # フィルター
        players = filter_player_with_status_and_full_name_en
        players = filter_key.present? && filter_value.present? ? filter_player(players, filter_key, filter_value) : players

        # ソート
        players = case sort_key
                  when 'alphabet'
                    players.sorted_with_player_original_info('last_name_en')
                  when 'evaluation', 'speed', 'stamina', 'power', 'technique', 'mental'
                    players.reverse_sorted_with_player_original_info(sort_key)
                  else
                    players.sorted_with_pf_250_regist_id
                  end

        # 選手リスト、最大件数、オフセット
        players = players.active_pf_250_regist_id(pf_250_regist_ids)
        total = players.count
        players_list = players.limit(limit).offset(offset)

        render json: { data: { total: total, sort_key: sort_key, limit: params[:limit]&.to_i, offset: offset&.to_i, player_list: ActiveModelSerializers::SerializableResource.new(players_list, each_serializer: V1::Mt::PlayerDetailSerializer) } }
      end

      def player_detail_revision
        pf_250_regist_id = params[:player_id]

        player = filter_player_with_status_and_full_name_en.includes(:player_race_results).find_by(player_original_info: { pf_250_regist_id: pf_250_regist_id })
        return render json: { data: nil } if player.blank?

        render json: { data: { player: ActiveModelSerializers::SerializableResource.new(player, serializer: V1::Mt::PlayerDetailRevisionSerializer) } }
      end

      def past_races
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.promoter_year_and_season_blank') unless valid_past_races_params?

        holds = if past_races_params.blank?
                  past_races_exist_holds
                else
                  past_races_params[:round_code].present? ? Hold.where(promoter_year: past_races_params[:promoter_year].to_i, period: past_races_params[:season], round: past_races_params[:round_code]) : Hold.where(promoter_year: past_races_params[:promoter_year].to_i, period: past_races_params[:season])
                end
        return render json: { data: nil } if holds.blank?

        render json: { data: { promoter_year: holds.first.promoter_year, season: holds.first.period, race_list: past_races_list(holds) } }
      end

      def race_details
        raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.datas.race_id_blank') if params[:race_id].blank?

        target_race = Race.includes(:hold_daily_schedule).find_by(id: params[:race_id])

        # レースが存在しない場合はreturn
        return render json: { data: nil } if target_race.blank?

        race_players = target_race.race_detail&.race_players&.mt_api_race_player_scope&.preload(:race_player_stat)
        race_table = race_players.nil? ? [] : race_table(target_race, race_players)
        serialized_hold_daily_schedule = ActiveModelSerializers::SerializableResource.new(target_race.hold_daily_schedule, serializer: V1::Mt::HoldDailyScheduleSerializer)

        # hold_daily_scheduleまたはrace_tableが存在しない場合はreturn
        return render json: { data: nil } if race_table.blank? || serialized_hold_daily_schedule.blank?

        serialized_payoff_list = ActiveModelSerializers::SerializableResource.new(PayoffList.mt_api_payoff_scope(target_race.race_detail&.id), each_serializer: V1::Mt::PayoffListSerializer)
        render json: {
          data: {
            name: race_name(target_race.event_code),
            detail: target_race.details_code,
            cancel_status: cancel_status(target_race),
            hold_daily_schedule: serialized_hold_daily_schedule,
            race_table: race_table,
            free_text: target_race.formated_free_text,
            race_movie_yt_id: target_race.race_movie_yt_id,
            interview_movie_yt_id: target_race.interview_movie_yt_id,
            payoff_list: serialized_payoff_list,
            post_time: time_format(target_race.post_time)
          }
        }
      end

      def search_sort_items
        country_list = PlayerOriginalInfo.pluck(:free2).compact
        name_list = PlayerOriginalInfo.pluck(:last_name_en).compact.map(&:first)
        evaluation_list = PlayerOriginalInfo.pluck(:evaluation).compact.map { |evaluation| Player.evaluation_select(evaluation) }
        render json: { data: { country: list_items(country_list), initial: list_items(name_list), evaluation: list_items(evaluation_list) } }
      end

      def scheduled_seasons
        # 現在日時から２日前と比較して未来の開催が属するシーズンを全て返す（最大２配列）
        select_hold = Hold.filter_hold_with_season.current_or_future.order(:first_day).pluck(:promoter_year, :period).uniq
        # 未来に対象の開催がない場合は、日付で見て最後に登録されている開催を参照
        select_hold = Hold.filter_hold_with_season.order('first_day DESC').pluck(:promoter_year, :period).first(1) if select_hold.empty?

        seasons = select_hold.first(2).map do |hold|
          { promoter_year: hold[0],
            season: hold[1] }
        end
        render json: { data: { scheduled_seasons: seasons } }
      end

      private

      def current_season_hold
        # 現在開催中のシーズン取得(開催初日が２日前より、先の日付。開催初日で昇順に並べfirstが対象)
        select_hold = Hold.filter_hold_with_round.select(:id, :season, :promoter_year, :period, :round, :first_day, :hold_days, :tt_movie_yt_id, :hold_status)
        current_season_hold = select_hold.current_or_future
                                         .order(:first_day).first
        # 現在開催中のシーズン取得ができなかった場合（開催初日降順のfirstを取得）
        current_season_hold ||= select_hold.order('first_day DESC').first

        current_season_hold
      end

      def player_list(race)
        player_ids = race.race_detail&.race_players&.pluck(:pf_player_id)
        # 取得できない場合は、空配列を返す
        return [] if player_ids.nil?

        filter_player_with_status_and_full_name_en.where(pf_player_id: player_ids)
      end

      def player_list_with_bike_no(race)
        race_players = race.race_detail&.race_players&.pluck(:pf_player_id, :bike_no)
        # 取得できない場合は、空配列を返す
        return [] if race_players.blank?

        players = filter_player_with_status_and_full_name_en.where(pf_player_id: race_players.map { |arr| arr[0] }).to_a
        players.map do |player|
          bike_no = race_players.find { |race_player| race_player[0] == player.pf_player_id }[1]
          Serializers::PlayerListDetail.new(bike_no: bike_no, player: player)
        end
      end

      def promoter_year_finalist(period)
        final_race = @target_holds.find_by(period: period)&.races&.includes(race_detail: :race_players)&.find_by(event_code: '3')
        return { race_id: nil, date: nil, player_list: [] } if final_race.nil?

        pf_250_regist_id_list = player_list(final_race).map(&:pf_250_regist_id)
        { race_id: final_race.id, date: final_race.race_detail&.hold_day&.to_date&.strftime('%Y-%m-%d'), player_list: pf_250_regist_id_list }
      end

      def set_final_holds
        @target_holds = Hold.where(promoter_year: params[:promoter_year] || fiscal_year(Time.zone.now), round: 301).includes(:races)
      end

      def valid_params?
        return true if params[:promoter_year].blank?

        params[:season].present? && params[:round_code].present?
      end

      def find_hold_daily_schedule
        # TODO: ロジック正しい？今日のこれからのレースは取りこぼさない？
        upcoming_hold_daily_races = HoldDaily.includes(:races, :hold).filter_races_holds.where('event_date > ?', Time.zone.now).order(:event_date).first&.races&.select { |r| r.race_detail&.race_result.blank? }
        if upcoming_hold_daily_races.present?
          [upcoming_hold_daily_races.first.hold_daily_schedule]
        else
          [HoldDailySchedule.includes(:races, hold_daily: :hold).filter_races.filter_holds.order('hold_dailies.event_date').last]
        end
      end

      def past_races_params
        params.permit(:promoter_year, :season, :round_code)
      end

      def past_races_exist_holds
        finished_race = RaceDetail.includes(:race_result, { race: { hold_daily_schedule: { hold_daily: :hold } } }).order(:first_day).select { |r| r.race_result&.race_stts == '15' }&.last&.race
        last_finished_hold = finished_race&.hold_daily_schedule&.hold_daily&.hold
        last_finished_period = last_finished_hold&.period
        last_finished_promoter_year = last_finished_hold&.promoter_year
        Hold.where.not(promoter_year: nil)
            .where.not(period: nil)
            .where(promoter_year: last_finished_promoter_year, period: last_finished_period)
      end

      def valid_past_races_params?
        # パラメータ指定しない場合
        return true if past_races_params.blank?

        past_races_params[:promoter_year].present? && past_races_params[:season].present?
      end

      def past_races_list(holds)
        holds.each_with_object([]) do |hold, arr|
          hold.hold_dailies.map do |hold_daily|
            event_date = hold_daily.event_date.strftime('%Y-%m-%d')
            hold_daily.hold_daily_schedules.map do |hold_daily_schedule|
              day_night = hold_daily_schedule.daily_no_before_type_cast
              hold_daily_schedule.races.map do |race|
                arr << {
                  id: race.id,
                  event_date: event_date,
                  day_night: day_night,
                  post_time: time_format(race.post_time),
                  name: race_name(race.event_code),
                  detail: race.details_code,
                  cancel_status: cancel_status(race),
                  race_status: race_status(race),
                  player_list: ActiveModelSerializers::SerializableResource.new(player_list(race), each_serializer: V1::Mt::PlayerDetailSerializer)
                }
              end
            end
          end
        end
      end

      def fiscal_year(datetime)
        datetime.month <= 3 ? datetime.year - 1 : datetime.year
      end

      def time_format(time_text)
        return '' if time_text.blank?

        seconds_str = time_text.slice!(-2, 2)
        format('%<minutes>02d:%<seconds>02d', minutes: time_text.to_i, seconds: seconds_str.to_i)
      end

      def get_win_odds_values(race_detail)
        # オッズ集計日時（odds_info.odds_time）が最新であるodds_info
        latest_odds_info = race_detail.odds_infos.order(odds_time: :desc).first
        # odds_infoがない場合は、空hashを返す
        return {} if latest_odds_info.blank?

        # 賭式タイプが単勝であるodds_listのodds_details
        win_odds_details = latest_odds_info.odds_lists.find_by(vote_type: 10)&.odds_details
        # odds_detailsがない場合は、空hashを返す
        return {} if win_odds_details.blank?

        win_odds_values = {}
        race_detail.race_players.map do |race_player|
          # odds_detailsの中で1着車番がレース選手の車番であるオッズ値
          win_odds_values[race_player.bike_no] = win_odds_details.find_by(tip1: race_player.bike_no)&.odds_val&.to_f
        end
        win_odds_values
      end

      def get_tt_player(hold_id, pf_player_id)
        TimeTrialPlayer.includes(:time_trial_result).find_by(time_trial_result: { hold_id: hold_id }, pf_player_id: pf_player_id)
      end

      def race_table(target_race, race_players) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
        race_players.each_with_object([]) do |race_player, arr|
          # パラメータの必須確認
          next if race_player.bike_no.blank?

          race_detail = race_player&.race_detail
          tt_player = get_tt_player(target_race.hold_daily_schedule.hold_id, race_player.pf_player_id)
          win_odds_values = get_win_odds_values(target_race.race_detail)
          player = Player.includes(:player_original_info)
                         .where.not(player_original_info: { pf_250_regist_id: nil })
                         .where.not(player_original_info: { last_name_en: nil })
                         .where.not(player_original_info: { first_name_en: nil })
                         .find_active_pf_player_id(race_player.pf_player_id)
          # パラメータの必須確認
          serialized_player = player.blank? ? next : ActiveModelSerializers::SerializableResource.new(player, serializer: V1::Mt::PlayerDetailSerializer)
          # スターティングポジションは、2021/10/11以前の場合 => nullを返す。race_detail.hold_dayがnilの場合 => race_player.start_positionを返す。
          start_position = if race_detail.hold_day.blank?
                             race_player.start_position
                           elsif race_detail.hold_day.to_date >= Date.parse('2021/10/11')
                             race_player.start_position
                           end
          tt_time = if tt_player&.total_time == 99.9999 || tt_player&.total_time == 99.999 # rubocop:disable Lint/FloatComparison
                      nil
                    else
                      tt_player&.total_time&.to_f
                    end

          arr << { bike_no: race_player.bike_no,
                   cancel: race_player.miss,
                   tt_time: tt_time,
                   tt_rank: tt_player&.ranking,
                   gear: race_player.gear&.to_f,
                   start_position: start_position,
                   odds: win_odds_values[race_player.bike_no],
                   race_time: race_player.result_time,
                   race_rank: race_player.result_rank,
                   race_difference_code: race_player.result_difference_code,
                   player: serialized_player,
                   winner_rate: race_player.race_player_stat&.winner_rate,
                   '2quinella_rate' => race_player.race_player_stat&.second_quinella_rate,
                   '3quinella_rate' => race_player.race_player_stat&.third_quinella_rate,
                   last_round_result: last_round_result(race_detail&.pf_hold_id, player) }
        end
      end

      def filter_player(players, filter_key, filter_value)
        case filter_key
        when 'country'
          players.includes(:player_original_info).where(player_original_info: { free2: filter_value })
        when 'initial'
          ids = players.select { |player| player.last_name_en&.chars&.first == filter_value }.pluck(:id)
          players.where(id: ids)
        when 'evaluation'
          ids = players.select { |player| ::Player::EVALUATION_RANGES[filter_value.to_sym]&.cover?(player.evaluation) }.pluck(:id)
          players.where(id: ids)
        end
      end

      def filter_player_with_status_and_full_name_en
        Player.includes(:player_original_info, :player_result)
              .where.not(player_original_info: { pf_250_regist_id: nil })
              .where.not(player_original_info: { last_name_en: nil })
              .where.not(player_original_info: { first_name_en: nil })
      end

      # 1:平常
      # 2:中止
      # 出走表（race_detail）が確定前（nil）で開催が終了していた場合(hold_statusが0,1以外)は中止。
      # レース状況（race_status）がnil, レース前（0)、レース成立（10）、レース終了（15）以外の場合は中止。
      def cancel_status(race)
        if race.race_detail.blank?
          return %w[before_held being_held].exclude?(race.hold_daily_schedule.hold.hold_status) ? 2 : 1
        end

        [nil, '0', '10', '15'].exclude?(race.race_detail.race_status) ? 2 : 1
      end

      # 出走表、あるいは出走選手がない：１
      # 出走表、出走選手はあるがレース結果がない：２
      # レース結果がある：３
      def race_status(race)
        return 1 if race.race_detail.blank? || race.race_detail.race_players.blank?

        race.race_detail.race_result.blank? ? 2 : 3
      end

      def list_items(list)
        list.uniq.map do |item|
          [item, list.count { |it| it == item }]
        end
      end

      def race_name(event_code)
        return 'T' if %w[W X Y].include? event_code

        event_code
      end

      def mediated_player_list(mediated_players_array)
        # 補充リスト
        additioal_list = mediated_players_array.select { |player| MediatedPlayer::ADDITIONAL_CODE.include?(player.issue_code) }

        # 欠場・途中欠場のリスト
        cancelled_mediated_players = mediated_players_array.select { |player| player.miss_day.present? }
        absence_list = cancelled_mediated_players.select { |player| player.join_code.present? }
        cancelled_list = cancelled_mediated_players.select { |player| player.join_code.blank? }

        # 全体から補充リストを引いたものが一覧リストの対象者[途中欠場（補充選手は除く）も出場選手一覧に含む]
        target_mediated_players_array = mediated_players_array - additioal_list
        pf_250_regist_id_list = target_mediated_players_array.select { |player| player.miss_day.blank? } + absence_list - additioal_list

        {
          additioal_list: additioal_list,
          absence_list: absence_list,
          cancelled_list: cancelled_list,
          pf_250_regist_id_list: pf_250_regist_id_list
        }
      end

      def pf_250_regist_id_arr(mediated_player_list)
        mediated_player_list.map(&:pf_250_regist_id)
      end

      def full_name_arr(mediated_player_list)
        mediated_player_list.map(&:full_name).compact
      end

      def last_round_result(pf_hold_id, player) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        hold_players = HoldPlayer.joins(:hold).where(holds: { pf_hold_id: pf_hold_id })
        hold_players = hold_players.eager_load(last_hold_player: [:hold, :race_result_players])
        hold_player = hold_players.find_by(player: player)
        last_hold_player = hold_player&.last_hold_player
        last_hold = last_hold_player&.hold
        return nil if last_hold.blank?

        tt_player = last_hold&.time_trial_result&.time_trial_players&.find_by(pf_player_id: player.pf_player_id)
        tt_time = if tt_player&.total_time.to_d == 99.9999.to_d || tt_player&.total_time.to_d == 99.999.to_d
                    nil
                  else
                    tt_player&.total_time&.to_f
                  end
        {
          promoter_year: last_hold.promoter_year,
          season: last_hold.period,
          round_code: last_hold.round,
          event_date: last_hold.first_day,
          tt_record: tt_time,
          tt_rank: tt_player&.ranking,
          race_list: race_list(last_hold_player)
        }
      end

      def race_list(hold_player)
        return [] if hold_player.blank?

        associations = {
          race_result: {
            race_detail: {
              race: {
                hold_daily_schedule: :hold_daily
              }
            }
          }
        }
        race_result_players = hold_player.race_result_players.eager_load(associations).order('hold_dailies.event_date').order('races.program_no')
        race_result_players.map do |race_result_player|
          race_detail = race_result_player.race_result.race_detail
          rank = race_result_player.rank.to_i >= 1 ? race_result_player.rank : nil
          unless rank
            code = race_result_player.result_event_codes.order(:priority)&.first&.event_code
            rank = WordCode.find_by(identifier: 'V12', code: code)&.name1 if code.present?
          end
          {
            event_code: race_name(race_detail.event_code),
            details_code: race_detail.details_code,
            race_rank: rank.to_s
          }
        end
      end
    end
  end
end
