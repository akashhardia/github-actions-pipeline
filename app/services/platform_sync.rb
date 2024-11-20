# frozen_string_literal: true

# APIアクセス時に使用されるトークンを処理する
module PlatformSync
  class << self
    def hold_update!(year: nil, month: nil, hold_id: nil)
      raise PfApiError, I18n.t('custom_errors.platform.input_year_and_month') if year.blank? != month.blank?
      raise PfApiError, I18n.t('custom_errors.platform.holds_update.params_blank') if [year, month, hold_id].all?(&:blank?)
      raise PfApiError, I18n.t('custom_errors.platform.holds_update.input_either_year_and_month_or_hold_id') if [year, month, hold_id].all?(&:present?)

      response = ApiProvider.platform.get_calendar(year: year, month: month, hold_id: hold_id)

      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: 'hold_list') if response['result_code'] != 100

      ApplicationRecord.transaction do
        hold_and_association_update!(response)
      end
    end

    def hold_bulk_update!(hold_id_list)
      raise PfApiError, I18n.t('custom_errors.platform.hold_id_list_blank') if hold_id_list.blank?

      ApplicationRecord.transaction do
        hold_id_list.each do |hold_id|
          response = ApiProvider.platform.get_calendar(hold_id: hold_id)

          raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: 'hold_list') if response['result_code'] != 100

          hold_and_association_update!(response)
        end
      end
    end

    def player_update(update_date, pf_player_id)
      return Rails.logger.error I18n.t('custom_errors.platform.confirm_params') if [update_date, pf_player_id].all?(&:present?) || [update_date, pf_player_id].all?(&:blank?)

      response = ApiProvider.platform.get_player_master(update_date: update_date, player_id: pf_player_id)
      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      player_and_original_info_upsert(response['id_list'])
    end

    def player_update_by_250id(pf_250id)
      return Rails.logger.error I18n.t('custom_errors.platform.specify_params') if pf_250id.blank?

      response = ApiProvider.platform.get_player_master_by_250id(pf_250id: pf_250id)
      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      player_and_original_info_upsert(response['id_list'])
    end

    # 月を指定して、その間に開かれるholdに対してrace_detailを取得していく
    def race_details_get(year_month)
      raise PfApiError, I18n.t('custom_errors.platform.params_blank') if year_month.blank?

      holds = Hold.where(first_day: Date.strptime(year_month.to_s, '%Y_%m').in_time_zone.all_month)

      holds.each do |hold|
        hold.hold_dailies.pluck(:hold_id_daily).uniq.each do |hold_id_daily|
          hold_daily = hold.hold_dailies.find_by(hold_id_daily: hold_id_daily)
          # hold_dailyが0のものは、raceはなく出走表もないため出走表取得APIを投げない
          next if hold_daily.hold_daily.zero?

          race_detail_get(hold.pf_hold_id, hold_id_daily)
        end
      end
    end

    # hold,hold_id_dailyを指定してrace_detailを取得していく
    def race_detail_get(pf_hold_id, hold_id_daily)
      raise PfApiError, I18n.t('custom_errors.platform.params_blank') if pf_hold_id.blank? || hold_id_daily.blank?

      response = ApiProvider.platform.get_race_table(pf_hold_id, hold_id_daily)
      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: '出走表') if response['result_code'] != 100

      response['race_table'].each do |race_info|
        race = HoldDaily.find_by!(hold_id_daily: hold_id_daily).races.find_by(program_no: race_info['program_no'])
        next Rails.logger.error I18n.t('custom_errors.platform.race_not_found') if race.blank?

        detail_response = ApiProvider.platform.get_race_detail(race_info['entries_id'])
        next Rails.logger.error I18n.t('custom_errors.platform.target_not_found', target: '出走表詳細') if detail_response['result_code'] != 100

        ApplicationRecord.transaction do
          race.update!(entries_id: race_info['entries_id'])
          race_detail = race.race_detail
          if race_detail.blank?
            race_detail_and_association_create!(race.build_race_detail(race_detail_params_format(detail_response)), detail_response)
          else
            race_detail_and_association_update!(race_detail, detail_response)
          end
        end
      end
    end

    # entries_idを指定してrace_detailを取得して登録、更新する
    def race_detail_upsert!(entries_id)
      race = Race.find_by(entries_id: entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.params_or_target_blank', target: 'レース') if entries_id.blank? || race.blank?

      response = ApiProvider.platform.get_race_detail(entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: '出走表詳細') if response['result_code'] != 100

      ApplicationRecord.transaction do
        race_detail = race.race_detail
        race_detail.blank? ? race_detail_and_association_create!(race.build_race_detail(race_detail_params_format(response)), response) : race_detail_and_association_update!(race_detail, response)
      end
    end

    # pf_hold_idを指定してmediated_playerを取得し、holdとplayerを紐づける、issue_typeは特に指定がなければ0:全て取得になる、1:出場選手,2:欠場選手
    # すでに開催のあっせん選手を取得している場合は更新する
    def mediated_players_upsert!(pf_hold_id, _issue_type = 0)
      hold = Hold.find_by(pf_hold_id: pf_hold_id)
      raise PfApiError, I18n.t('custom_errors.platform.params_or_target_blank', target: '開催') if hold.blank?

      response = ApiProvider.platform.get_mediated_players(pf_hold_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: 'あっせん選手情報') if response['result_code'] != 100

      ApplicationRecord.transaction do
        mediated_player_list_upsert!(hold, response['issue_list'])
      end
    end

    def holding_word_codes_update(update_date)
      raise PfApiError, I18n.t('custom_errors.platform.confirm_params') if update_date.blank?

      # pfからupdate_dateを指定してデータ取得
      pf_holding_master_response = ApiProvider.platform.get_holding_master(update_date: update_date)
      raise PfApiError, I18n.t('custom_errors.platform.not_found') if pf_holding_master_response['result_code'] != 100

      ApplicationRecord.transaction do
        pf_holding_master_response['id_list'].each do |word_code_response|
          word_code_and_names_update!(word_code_response)
        end
      end
    end

    # pf_hold_idを指定してtime_trial_resultを取得していく
    def time_trial_result_upsert!(pf_hold_id)
      raise PfApiError, I18n.t('custom_errors.platform.hold_id_blank') if pf_hold_id.blank?

      hold = Hold.find_by(pf_hold_id: pf_hold_id)
      # holdは必須なのでない場合は作成しない
      raise PfApiError, I18n.t('custom_errors.platform.target_hold_blank') if hold.blank?

      response = ApiProvider.platform.get_time_trial_result(pf_hold_id)

      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      ApplicationRecord.transaction do
        time_trial_result_and_association_upsert!(hold, response)
      end
    end

    # entries_idを指定してrace_resultを取得して登録する
    def race_result_get(entries_id)
      race_detail = RaceDetail.includes(race_result: { race_result_players: [:result_event_codes, :hold_player_result] }).find_by(entries_id: entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.params_or_target_blank', target: '出走表詳細') if entries_id.blank? || race_detail.blank?

      response = ApiProvider.platform.get_race_result(entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: 'レース結果') if response['result_code'] != 100

      response_race_detail = ApiProvider.platform.get_race_detail(entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: '出走表詳細') if response_race_detail['result_code'] != 100

      ApplicationRecord.transaction do
        # レース結果、払戻情報があれば一旦削除して、再度作成する
        race_detail.race_result&.destroy!
        race_detail.payoff_lists&.destroy_all
        race_result_and_association_create!(race_detail, response)
        race_detail_and_association_update!(race_detail, response_race_detail)
      end
    end

    # 施工者コードと開催年度を指定して、年間スケジュールを取得する
    def annual_schedule_update(promoter_code, promoter_year)
      raise PfApiError, I18n.t('custom_errors.platform.params_blank') if promoter_code.blank? || promoter_year.blank?

      response = ApiProvider.platform.get_annual_schedule(promoter_code, promoter_year)

      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      pf_ids = []
      schedule_upsert_list = response['hold_list'].map do |schedule|
        pf_ids << schedule['id']
        AnnualSchedule.new(schedule_params_format(schedule, promoter_year))
      end

      ApplicationRecord.transaction do
        AnnualSchedule.import! schedule_upsert_list, on_duplicate_key_update: get_column_name_symbols(AnnualSchedule)
        AnnualSchedule.where.not(pf_id: pf_ids).where(promoter_year: promoter_year).destroy_all
      end
    end

    # player_idとhold_idを指定して、選手レース戦績情報を取得する、player_idは必須
    def player_race_result_get(player_id, hold_id = nil)
      player = Player.find_by(pf_player_id: player_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_player_blank') if player.blank?

      response = ApiProvider.platform.get_player_race_results(player_id, hold_id)

      return if response['result_code'] == 805
      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      # hold_idが指定された場合は、指定されたhold_idの選手レース戦績を削除・追加し、指定がない場合は全消し全入れで対応する
      ApplicationRecord.transaction do
        hold_id.blank? ? player.player_race_results.destroy_all : player.player_race_results.where(hold_id: hold_id).destroy_all

        race_result_list = response['race_result'].map { |result| player.player_race_results.build(player_race_result_params_format(result)) }
        PlayerRaceResult.import!(race_result_list)
      end
    end

    # 選手IDを指定して、選手戦績情報を取得する
    def player_result_update(pf_player_id)
      player = Player.find_by(pf_player_id: pf_player_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_player_blank') if player.blank?

      response = ApiProvider.platform.get_player_result(pf_player_id)

      return if response['result_code'] == 805
      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      player_result = player.player_result
      player_result = player.build_player_result if player_result.nil?

      ApplicationRecord.transaction do
        player_result.update!(player_result_param_format(response))
        # hold_titleの作成
        hold_title_update!(player_result, response['hold_list'])
      end
    end

    def odds_info_get(entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.odds_info_update.params_blank') if entries_id.blank?

      race_detail = RaceDetail.find_by(entries_id: entries_id)
      raise PfApiError, I18n.t('custom_errors.platform.target_not_found', target: '出走表詳細') if race_detail.blank?

      response = ApiProvider.platform.get_race_status(entries_id)

      raise PfApiError, I18n.t('custom_errors.platform.not_found') if response['result_code'] != 100

      grouping_odds_list = response['odds']['odds_list'].group_by { |li| li['vote_type'] }

      ApplicationRecord.transaction do
        odds_info = race_detail.odds_infos.find_or_create_by!(odds_info_params_format(response['odds'], entries_id))

        odds_info.odds_lists.includes(:odds_details).destroy_all
        odds_details = response['odds']['vote_count'].map do |vote_count|
          odds_list = odds_info.odds_lists.create!(odds_list_params_format(vote_count))

          grouping_odds_list[odds_list.vote_type_before_type_cast].map do |list|
            odds_list.odds_details.build(odds_detail_params_format(list))
          end
        end.flatten

        OddsDetail.import!(odds_details)
      end
    end

    private

    def hold_title_update!(player_result, hold_list)
      # hold_listが空もしくはnilの場合、hold_titlesを全削除する
      return player_result.hold_titles.destroy_all if hold_list.blank?

      hold_title_list = hold_list.map do |li|
        hold_title = player_result.hold_titles.find_or_initialize_by(pf_hold_id: li['hold_id'])
        hold_title.update!(period: li['period'], round: li['round'])
        hold_title
      end

      # hold_title_listにないhold_titleは余分なので削除する
      (player_result.hold_titles - hold_title_list).each(&:destroy!)
    end

    def player_and_original_info_upsert(pf_player_list)
      ApplicationRecord.transaction do
        pf_player_list.map do |pf_player|
          # 250登録番号をキーとして、レコードが存在するplayer_original_infoを探す
          existing_player_original_info = PlayerOriginalInfo.find_by(pf_250_regist_id: pf_player['original_info']['250id'])
          # レコードが存在する場合、pfの情報に更新
          if existing_player_original_info.present?
            existing_player = existing_player_original_info.player
            existing_player_original_info.update!(player_original_info_params_format(pf_player['original_info']))
          # レコードが存在しない場合、プラットフォームの情報で新規追加 or 更新
          else
            existing_player = Player.find_or_create_by(pf_player_id: pf_player['player_id'])
            existing_player.create_player_original_info(player_original_info_params_format(pf_player['original_info']))
          end
          existing_player.update!(player_params_format(pf_player))
        end
      end
    end

    def race_result_and_association_create!(race_detail, response)
      race_result = race_detail.create_race_result!(race_result_params_format(response))

      response['players_list'].each do |player|
        race_result_player = race_result.race_result_players.create!(race_result_player_params_format(player))
        ResultEventCode.import!(player['event_code'].map.with_index { |event_code, index| race_result_player.result_event_codes.new(result_event_code_params_format(index, event_code)) }) if player['event_code'].present?
        next if race_result_player.race_canceled?

        hold_players = HoldPlayer.joins(hold: :races).where(races: { entries_id: response['entries_id'] })
        hold_player = hold_players.joins(:player).find_by(players: { pf_player_id: player['player_id'] })
        race_result_player.create_hold_player_result!(hold_player: hold_player) if hold_player
      end

      response['payoff_list'].each do |payoff|
        race_detail.payoff_lists.create!(payoff_list_params_format(payoff))
      end
    end

    def time_trial_result_and_association_upsert!(hold, response)
      result = hold.time_trial_result.presence || hold.build_time_trial_result(pf_hold_id: response['hold_id'])
      result.update!(confirm: response['confirm'], players: response['players'])

      pf_player_ids = response['players_list'].map do |params|
        player = result.time_trial_players.find_or_initialize_by(pf_player_id: params['player_id'])
        player.update!(time_trial_player_params_format(params))
        bike_info_params = params['bike_info']
        # time_trial_bike_infoなければ作成
        bike_info = player.time_trial_bike_info || player.build_time_trial_bike_info
        bike_info.update!(frame_code: bike_info_params['frame_code'])
        # time_trial_front_wheel_infoなければ作成
        front_wheel_info = bike_info.time_trial_front_wheel_info || bike_info.build_time_trial_front_wheel_info
        front_wheel_info.update!(bike_info_params['front_wheel_info'])
        # time_trial_rear_wheel_infoなければ作成
        rear_wheel_info = bike_info.time_trial_rear_wheel_info || bike_info.build_time_trial_rear_wheel_info
        rear_wheel_info.update!(bike_info_params['rear_wheel_info'])

        params['player_id']
      end

      # 速報連携時に事実と異なった選手番号で登録されていた場合は確定連携時に削除する
      result.time_trial_players.where(pf_player_id: result.time_trial_players.pluck(:pf_player_id) - pf_player_ids).map(&:destroy!) if response['confirm']
    end

    def race_detail_and_association_update!(race_detail, response)
      race_detail.update!(race_detail_params_format(response))
      # vote_infoについては特定できないので、全消しして新しく登録する
      race_detail.vote_infos.destroy_all
      response['vote_list'].each { |vote| race_detail.vote_infos.create!(vote) }

      response['players_list'].each do |player|
        race_player = race_detail.race_players.find_by(pf_player_id: player['player_id'])
        next Rails.logger.error I18n.t('custom_errors.platform.race_player_not_found') if race_player.blank?

        race_player.update!(race_player_params_format(player))
        bike_info_params = player['bike_info']
        race_player.bike_info.update!(frame_code: bike_info_params['frame_code'])
        race_player.bike_info.front_wheel_info.update!(bike_info_params['front_wheel_info'])
        race_player.bike_info.rear_wheel_info.update!(bike_info_params['rear_wheel_info'])
      end
    end

    def race_detail_and_association_create!(race_detail, response)
      response['players_list']&.each do |player|
        race_player = race_detail.race_players.new(race_player_params_format(player))
        bike_info_params = player['bike_info']
        bike_info = race_player.build_bike_info(frame_code: bike_info_params['frame_code'])
        bike_info.build_front_wheel_info(bike_info_params['front_wheel_info'])
        bike_info.build_rear_wheel_info(bike_info_params['rear_wheel_info'])
        race_player.build_race_player_stat(generate_race_player_stat_params(player['player_id']))
      end

      race_detail.save!

      VoteInfo.import!(response['vote_list'].map { |vote| race_detail.vote_infos.new(vote) })
    end

    # PlayerResultからRacePlayerStatにコピーするパラメータを指定
    def generate_race_player_stat_params(pf_player_id)
      player_result = PlayerResult.find_by(pf_player_id: pf_player_id)
      player_result&.slice(:winner_rate, :second_quinella_rate, :third_quinella_rate)
    end

    # 開催がない場合の処理
    def holds_and_association_create!(pf_hold)
      hold = Hold.create!(hold_params_format(pf_hold))
      pf_hold['days_list'].each do |pf_day|
        hold_daily = hold.hold_dailies.create!(hold_daily_params_format(pf_day))

        next if pf_day['race_list'].blank?

        hold_daily_schedule_list = hold_daily_schedules_and_races_create!(pf_day['race_list'], hold_daily)

        # 販売情報登録
        seat_sale_create!(hold_daily_schedule_list)
      end
    end

    def hold_and_association_update!(response)
      response['hold_list'].each do |hold_params|
        # ステージングと本番環境では千葉市以外の開催は取得しない
        next if (Rails.env.production? || Rails.env.staging?) && hold_params['promoter_code'] != '4160'

        # 対象のHoldがない場合は、作成する
        hold = Hold.find_by(pf_hold_id: hold_params['hold_id'])
        next holds_and_association_create!(hold_params) if hold.blank?

        hold.update!(hold_params_format(hold_params))
        hold_params['days_list'].each do |pf_day|
          hold_daily = hold.hold_dailies.find_or_create_by(hold_id_daily: pf_day['hold_id_daily'])
          hold_daily.update!(hold_daily_params_format(pf_day))

          # program_noから対象のレースがあれば更新、program_noがなくて出走表もないレースは削除
          # hold_daily_scheduleもなければ作成する、余分なものは削除する
          create_or_update_race_list!(hold_daily, pf_day['race_list'])

          # raceを持たなくなった、hold_daily_scheduleは削除する
          hold_daily.hold_daily_schedules.each do |h|
            h.destroy! if h.reload.races.blank?
          end
        end

        seat_sale_create!(hold.hold_daily_schedules)
      end
    end

    def create_or_update_race_list!(hold_daily, pf_race_list)
      race_program_no_list = hold_daily.races.pluck(:program_no)
      pf_race_list.each do |pf_race|
        hold_daily_schedule = find_or_create_hold_daily_schedule!(hold_daily, pf_race)
        race = create_or_update_race!(hold_daily_schedule, pf_race)
        race_program_no_list.delete(race.program_no)
      end

      # 不要なレースを削除
      destroy_races!(hold_daily, race_program_no_list)
    end

    def find_or_create_hold_daily_schedule!(hold_daily, pf_race)
      return hold_daily.hold_daily_schedules.find_or_create_by(daily_no: :am) if Constants::PRIORITIZED_AM_EVENT_CODE_LIST.include?(pf_race['event_code'])

      hold_daily.hold_daily_schedules.find_or_create_by(daily_no: :pm)
    end

    def create_or_update_race!(hold_daily_schedule, pf_race)
      race = hold_daily_schedule.hold_daily.races.find_or_initialize_by(program_no: pf_race['program_no'])
      pf_race['post_start_time'] = '2000/01/01' if pf_race['post_start_time'].blank?
      pf_race['hold_daily_schedule_id'] = hold_daily_schedule.id
      race.update!(pf_race)
      race
    end

    def destroy_races!(hold_daily, race_program_no_list)
      races = hold_daily.races.where(program_no: race_program_no_list)
      races.where(entries_id: nil).map(&:destroy!) # 出走表が存在するレースは残す
    end

    def hold_daily_schedules_and_races_create!(pf_race_list, hold_daily)
      # 1日の全レースのevent_codeリストに午前/午後のevent_codeが存在すればhold_daily_scheduleを作成
      event_code_list = pf_race_list.map { |race| race['event_code'] }
      hold_daily_schedule_list = []

      if Constants::PRIORITIZED_AM_EVENT_CODE_LIST.any? { |am_event_code| event_code_list.include?(am_event_code) }
        hold_daily_schedule_am = hold_daily.hold_daily_schedules.create!(daily_no: :am)
        hold_daily_schedule_list << hold_daily_schedule_am
      end
      if Constants::PRIORITIZED_PM_EVENT_CODE_LIST.any? { |pm_event_code| event_code_list.include?(pm_event_code) }
        hold_daily_schedule_pm = hold_daily.hold_daily_schedules.create!(daily_no: :pm)
        hold_daily_schedule_list << hold_daily_schedule_pm
      end
      pf_race_list_race(pf_race_list, hold_daily_schedule_am, hold_daily_schedule_pm)
      hold_daily_schedule_list
    end

    def pf_race_list_race(pf_race_list, hold_daily_schedule_am, hold_daily_schedule_pm)
      pf_race_list.each do |race|
        race['post_start_time'] = '2000/01/01' if race['post_start_time'].blank?
        if Constants::PRIORITIZED_AM_EVENT_CODE_LIST.include? race['event_code']
          hold_daily_schedule_am.races.create!(race)
        elsif Constants::PRIORITIZED_PM_EVENT_CODE_LIST.include? race['event_code']
          hold_daily_schedule_pm.races.create!(race)
        end
      end
    end

    # あっせん選手情報を登録、更新する、pf_player_idで選手が見つからない場合はエラーを上げる
    def mediated_player_list_upsert!(hold, response)
      return if response.blank? # あっせん選手情報がない場合は何もしない

      response.each do |mediated|
        player = Player.find_by(pf_player_id: mediated['player_id'])
        raise PfApiError, I18n.t('custom_errors.platform.target_player_blank') if player.blank?

        # hold_playerが見つからなければ作成する
        hold_player = hold.hold_players.find_or_create_by!(player_id: player.id)
        LastHoldPlayerResolver.resolve(hold_id: hold_player.hold_id, player_id: hold_player.player_id)

        # player_idはpf_player_idで保存する必要があるためキーを変更している
        mediated_player = hold_player.mediated_player || hold_player.build_mediated_player
        mediated_player.update!(mediated.tap { |res| res['pf_player_id'] = res.delete('player_id') })
      end
    end

    def word_code_and_names_update!(word_code_response)
      word_code = WordCode.find_or_initialize_by(master_id: word_code_response['master_id'])
      word_code.attributes = word_code_params_format(word_code_response)
      word_code.save!
      word_code_response['name_list'].map do |name|
        word_name = word_code.word_names.find_or_initialize_by(lang: name['lang'])
        word_name.attributes = word_name_params_format(name)
        word_name.save!
      end
    end

    # モデルのカラム名のシンボルの配列を取得
    def get_column_name_symbols(model)
      column_name_symbols = model.column_names.map(&:to_sym)
      column_name_symbols.delete(:id)
      column_name_symbols.delete(:created_at)
      column_name_symbols.delete(:active) if model == AnnualSchedule
      column_name_symbols
    end

    def seat_sale_create!(hold_daily_schedule_list)
      hold_daily_schedule_list.each do |hold_daily_schedule|
        # 既に販売情報が存在する場合は新しく作る必要がない
        next if hold_daily_schedule.seat_sales.present?

        schedule = TemplateSeatSaleSchedule.target_find_by(hold_daily_schedule)
        # hold_daily_scheduleに対して、自動生成の値が見つからなければ販売情報は作成しない
        # 開催日が過ぎているものも販売情報は作成しない
        next if schedule.blank? || hold_daily_schedule.hold_daily.event_date < Time.zone.today

        event_date = hold_daily_schedule.hold_daily.event_date.to_s
        params = {
          hold_daily_schedule_id: hold_daily_schedule.id,
          template_seat_sale_id: schedule.template_seat_sale_id,
          sales_start_at: Time.zone.now,
          sales_end_at: Time.zone.parse("#{event_date} #{schedule.sales_end_time}"),
          admission_available_at: Time.zone.parse("#{event_date} #{schedule.admission_available_time}"),
          admission_close_at: Time.zone.parse("#{event_date} #{schedule.admission_close_time}")
        }
        # チケット登録
        creator = TicketsCreator.new(params)
        creator.create_all_tickets!
      end
    end

    def player_params_format(pf_player)
      {
        pf_player_id: pf_player['player_id'],
        regist_num: pf_player['regist_num'],
        player_class: pf_player['player_class'],
        delete_day: pf_player['delete_day'],
        keirin_regist: pf_player['keirin_regist'],
        keirin_update: pf_player['keirin_update'],
        keirin_delete: pf_player['keirin_delete'],
        keirin_expiration: pf_player['keirin_expiration'],
        name_jp: pf_player['name_list']&.find { |list| list['lang'] == 'jp' }&.fetch('name', ''),
        name_en: pf_player['name_list']&.find { |list| list['lang'] == 'en' }&.fetch('name', ''),
        birthday: pf_player['birthday'],
        gender_code: pf_player['gender_code'],
        country_code: pf_player['country_code'],
        area_code: pf_player['area_code'],
        graduate: pf_player['graduate'],
        current_rank_code: pf_player['current_rank_code'],
        next_rank_code: pf_player['next_rank_code'],
        height: pf_player['height'],
        weight: pf_player['weight'],
        chest: pf_player['chest'],
        thigh: pf_player['thigh'],
        leftgrip: pf_player['leftgrip'],
        rightgrip: pf_player['rightgrip'],
        vital: pf_player['vital'],
        spine: pf_player['spine'],
        max_speed: pf_player['max_speed'],
        dash: pf_player['dash'],
        duration: pf_player['duration'],
        lap_200: pf_player['200lap'],
        lap_400: pf_player['400lap'],
        lap_1000: pf_player['1000lap']
      }
    end

    def hold_params_format(pf_hold)
      original_info = pf_hold['original_info'] || {}
      {
        pf_hold_id: pf_hold['hold_id'],
        track_code: pf_hold['track_code'],
        first_day: pf_hold['first_day'],
        hold_days: pf_hold['hold_days'],
        grade_code: pf_hold['grade_code'],
        purpose_code: pf_hold['purpose_code'],
        repletion_code: pf_hold['repletion_code'],
        hold_name_jp: pf_hold['hold_name_list']&.find { |list| list['lang'] == 'jp' }&.fetch('hold_name', ''),
        hold_name_en: pf_hold['hold_name_list']&.find { |list| list['lang'] == 'en' }&.fetch('hold_name', ''),
        hold_status: pf_hold['hold_status'].to_i,
        promoter_code: pf_hold['promoter_code'],
        promoter_year: pf_hold['promoter_year'],
        promoter_times: pf_hold['promoter_times'],
        promoter_section: pf_hold['promoter_section'],
        season: original_info['year_name'],
        period: original_info['period'],
        round: original_info['round'],
        girl: original_info['girl'],
        promoter: original_info['promoter'],
        time_zone: original_info['time_zone'],
        audience: original_info['audience'],
        title_jp: original_info['title_jp'],
        title_en: original_info['title_en'],
        first_day_manually: original_info['first_day']
      }
    end

    def hold_daily_params_format(pf_day)
      {
        program_count: pf_day['program_count'],
        hold_id_daily: pf_day['hold_id_daily'],
        event_date: pf_day['event_date'],
        hold_daily: pf_day['hold_daily'],
        daily_branch: pf_day['daily_branch'],
        race_count: pf_day['race_count'],
        daily_status: pf_day['daily_status'].to_i
      }
    end

    def race_detail_params_format(response)
      {
        pf_hold_id: response['hold_id'],
        hold_id_daily: response['hold_id_daily'],
        track_code: response['track_code'],
        hold_day: response['hold_day'],
        first_day: response['first_day'],
        hold_daily: response['hold_daily'],
        daily_branch: response['daily_branch'],
        entries_id: response['entries_id'],
        bike_count: response['bike_count'],
        laps_count: response['laps_count'],
        post_time: response['post_time'],
        grade_code: response['grade_code'],
        repletion_code: response['repletion_code'],
        race_code: response['race_code'],
        first_race_code: response['first_race_code'],
        entry_code: response['entry_code'],
        pattern_code: response['pattern_code'],
        type_code: response['type_code'],
        event_code: response['event_code'],
        details_code: response['details_code'],
        time_zone_code: response['time_zone_code'],
        race_status: response['race_status']
      }
    end

    def race_player_params_format(player)
      {
        bracket_no: player['bracket_no'],
        bike_no: player['bike_no'],
        pf_player_id: player['player_id'],
        gear: player['gear'],
        miss: player['miss'],
        start_position: player['start_position']
      }
    end

    def word_code_params_format(pf_holding_word_code)
      {
        master_id: pf_holding_word_code['master_id'],
        identifier: pf_holding_word_code['identifier'],
        code: pf_holding_word_code['code'],
        name1: pf_holding_word_code['name1'],
        name2: pf_holding_word_code['name2'],
        name3: pf_holding_word_code['name3']
      }
    end

    def word_name_params_format(pf_holding_word_name)
      {
        lang: pf_holding_word_name['lang'],
        name: pf_holding_word_name['name'],
        abbreviation: pf_holding_word_name['alias']
      }
    end

    def time_trial_player_params_format(player)
      {
        pf_player_id: player['player_id'],
        gear: player['gear'],
        first_time: player['first_time'],
        second_time: player['second_time'],
        total_time: player['total_time'],
        ranking: player['ranking'],
        grade_code: player['grade_code'],
        repletion_code: player['repletion_code'],
        race_code: player['race_code'],
        first_race_code: player['first_race_code'],
        entry_code: player['entry_code'],
        pattern_code: player['pattern_code']
      }
    end

    def race_result_params_format(result)
      {
        entries_id: result['entries_id'],
        bike_count: result['bike_count'],
        race_stts: result['race_stts'],
        post_time: result['post_time'],
        race_time: result['race_time'],
        last_lap: result['last_lap']
      }
    end

    def race_result_player_params_format(player)
      {
        bike_no: player['bike_no'],
        pf_player_id: player['player_id'],
        incoming: player['incoming'],
        rank: player['rank'],
        point: player['point'],
        trick_code: player['trick_code'],
        difference_code: player['difference_code'],
        home_class: player['home_class'],
        back_class: player['back_class'],
        start_position: player['start_position'],
        last_lap: player['last_lap']
      }
    end

    def result_event_code_params_format(priority, event_code)
      {
        priority: priority,
        event_code: event_code
      }
    end

    def payoff_list_params_format(result)
      {
        payoff_type: result['payoff_type'],
        vote_type: result['vote_type'],
        tip1: result['tip1'],
        tip2: result['tip2'],
        tip3: result['tip3'],
        payoff: result['payoff']
      }
    end

    def schedule_params_format(schedule, year)
      {
        pf_id: schedule['id'],
        first_day: schedule['first_day'],
        track_code: schedule['track_code'],
        hold_days: schedule['hold_days'],
        pre_day: schedule['pre_day'],
        year_name: schedule['year_name'],
        year_name_en: schedule['year_name_en'],
        period: schedule['period'],
        round: schedule['round'],
        girl: schedule['girl'],
        promoter_times: schedule['promoter_times'],
        promoter_section: schedule['promoter_section'],
        time_zone: schedule['time_zone'],
        audience: schedule['audience'],
        grade_code: schedule['grade_code'],
        promoter_year: year
      }
    end

    def player_result_param_format(result)
      {
        pf_player_id: result['player_id'],
        entry_count: result['entry_count'],
        run_count: result['run_count'],
        consecutive_count: result['consecutive_count'],
        first_count: result['1st_count'],
        second_count: result['2nd_count'],
        third_count: result['3rd_count'],
        outside_count: result['outside_count'],
        first_place_count: result['1st_place_count'],
        second_place_count: result['2nd_place_count'],
        third_place_count: result['3rd_place_count'],
        winner_rate: result['winner_rate'],
        second_quinella_rate: result['2quinella_rate'],
        third_quinella_rate: result['3quinella_rate']
      }
    end

    def player_original_info_params_format(original_info)
      # 国コードは3桁の数字にゼロパディング
      country_code = original_info['free2'].present? ? format('%03d', original_info['free2'].to_i) : ''

      {
        last_name_en: original_info['last_name_en'],
        last_name_jp: original_info['last_name_jp'],
        first_name_en: original_info['first_name_en'],
        first_name_jp: original_info['first_name_jp'],
        evaluation: original_info['evaluation'],
        experience: original_info['experience'],
        growth: original_info['growth'],
        popular: original_info['popular'],
        power: original_info['power'],
        mental: original_info['mental'],
        original_record: original_info['record'],
        speed: original_info['speed'],
        stamina: original_info['stamina'],
        technique: original_info['technique'],
        nickname: original_info['nickname'],
        comment: original_info['comment'],
        year_best: original_info['year_best'],
        season_best: original_info['season_best'],
        round_best: original_info['round_best'],
        race_type: original_info['race_type'],
        major_title: original_info['major_title'],
        pist6_title: original_info['pist6_title'],
        free1: original_info['free1'],
        free2: country_code,
        free3: original_info['free3'],
        free4: original_info['free4'],
        free5: original_info['free5'],
        free6: original_info['free6'],
        free7: original_info['free7'],
        free8: original_info['free8'],
        pf_250_regist_id: original_info['250id']
      }
    end

    def player_race_result_params_format(result)
      {
        hold_id: result['hold_id'],
        event_date: result['event_date'],
        hold_daily: result['hold_daily'],
        daily_status: result['daily_status']&.to_i,
        entries_id: result['entries_id'],
        race_no: result['race_no'],
        race_status: result['race_status'],
        rank: result['rank'],
        time: result['time'],
        event_code: result['event_code']
      }
    end

    def odds_info_params_format(odds, entries_id)
      {
        fixed: odds['fixed'],
        odds_time: odds['odds_time'],
        entries_id: entries_id
      }
    end

    def odds_list_params_format(vote_count)
      {
        vote_type: vote_count['vote_type'],
        odds_count: vote_count['count']
      }
    end

    def odds_detail_params_format(odds)
      {
        odds_max_val: odds['odds_max_val'],
        odds_val: odds['odds_val'],
        tip1: odds['tip1'],
        tip2: odds['tip2'],
        tip3: odds['tip3']
      }
    end
  end
end
