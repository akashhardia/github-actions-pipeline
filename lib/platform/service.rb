# frozen_string_literal: true

module Platform
  # 250 platform api fetcher
  class Service < Credential
    class << self
      # 開催日程情報を取得するAPI 月単位でデータを返す
      def get_calendar(year: nil, month: nil, hold_id: nil)
        request_params = { year: year, month: month, hold_id: hold_id }.compact.to_param
        get_api_response('/api/portal/calendar/seller', request_params)
      end

      # 選手マスタを取得する。日付を指定した場合、指定した日付以降更新された選手情報を取得する
      # updateを指定した場合、対象のデータがなければ、result_code=100でlist=0が返る
      def get_player_master(update_date: nil, player_id: nil)
        request_params = update_date ? "update=#{update_date}&original_flag=true" : "player_id=#{player_id}&original_flag=false"
        get_api_response('/api/portal/master/player', request_params)
      end

      # 250登録番号（250id）を指定して選手マスタを取得する。
      def get_player_master_by_250id(pf_250id: nil)
        request_params = "250id=#{pf_250id}&original_flag=true"
        get_api_response('/api/portal/master/player', request_params)
      end

      # hold,hold_id_dailyを指定してプログラムリストを取得
      def get_race_table(pf_hold_id, hold_id_daily)
        get_api_response('/api/portal/race_table/seller', "hold_id=#{pf_hold_id}&hold_id_daily=#{hold_id_daily}")
      end

      # entries_idを指定して出走表を取得する
      def get_race_detail(entries_id)
        get_api_response('/api/portal/race_detail', "entries_id=#{entries_id}")
      end

      # hold_idを指定してあっせん選手を取得する、issue_typeは特に指定がなければ0:全て取得になる、1:出場選手,2:欠場選手
      def get_mediated_players(hold_id, issue_type = 0)
        get_api_response('/api/portal/mediator_player', "hold_id=#{hold_id}&issue_type=#{issue_type}")
      end

      # 開催マスタ（用語コードと用語名の対応）を取得する。update_dateを指定した場合、指定した日付以降更新された用語コード/用語名を取得する
      # 対象のデータがなければ、result_code=100でid_list=[]が返る
      def get_holding_master(update_date: nil)
        request_params = "update=#{update_date}"
        get_api_response('/api/portal/master/holding', request_params)
      end

      # hold_idを指定してタイムトライアル情報を取得する
      def get_time_trial_result(hold_id)
        get_api_response('/api/portal/time_trial_result', "hold_id=#{hold_id}")
      end

      # entries_idを指定してレース結果を取得する
      def get_race_result(entries_id)
        get_api_response('/api/portal/race_result', "entries_id=#{entries_id}")
      end

      # promoter,yearを指定して年間スケジュールを取得する
      def get_annual_schedule(promoter, year)
        get_api_response('/api/portal/original/schedule', "promoter=#{promoter}&year=#{year}")
      end

      # player_id,hold_idを指定して選手レース戦績情報を取得する
      def get_player_race_results(player_id, hold_id)
        params = hold_id.present? ? "player_id=#{player_id}&hold_id=#{hold_id}" : "player_id=#{player_id}"
        get_api_response('/api/portal/original/player_racetime', params)
      end

      # player_idを指定して選手戦績情報を取得する
      def get_player_result(pf_player_id)
        get_api_response('/api/portal/original/player_result', "player_id=#{pf_player_id}")
      end

      # entries_idを指定してレース状況を取得する
      def get_race_status(entries_id)
        get_api_response('/api/portal/vote/race_status', "entries_id=#{entries_id}")
      end

      private

      def get_api_response(api_url, request_params)
        request_url = api_host_url + api_url + '?' + request_params
        result = HTTParty.get(request_url, headers: api_request_headers)
        begin
          # ログ保存
          ApiProvider.api_log(request_params, result)
        rescue StandardError => e
          Rails.logger.error e.to_s
        end
        result
      end

      def api_host_url
        "https://#{api_host}"
      end

      def api_request_headers
        {
          'X-Api-Id' => api_id,
          'X-Api-Key' => api_key
        }
      end
    end
  end
end
