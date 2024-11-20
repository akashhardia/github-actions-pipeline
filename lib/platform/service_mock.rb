# frozen_string_literal: true

module Platform
  # 250 platform api fetcher (mock)
  class ServiceMock < Credential
    class << self
      # 開催日程情報を取得するAPI 月単位でデータを返す
      def get_calendar(year: nil, month: nil, hold_id: nil)
        if year.present? && month.present?
          JSON.parse(File.read(Rails.root.join("lib/platform/mock_responses/year_#{year}_month_#{month}_holds.json")))
        else
          JSON.parse(File.read(Rails.root.join("lib/platform/mock_responses/hold_id_#{hold_id}_holds.json")))
        end
      rescue Errno::ENOENT
        # mockファイルが見つからなければ、対象データなしとしてのresponseを返す
        year.present? && month.present? ? { 'hold_list' => [], 'result_code' => 100 } : { 'result_code' => 805 }
      end

      # 選手マスタを取得する。日付を指定した場合、指定した日付以降更新された選手情報を取得する
      # updateを指定した場合、対象のデータがなければ、result_code=100でlist=0が返る
      def get_player_master(update_date: nil, player_id: nil)
        yesterday = update_date == '20220112' ? '_20220112' : nil
        if update_date.present?
          JSON.parse(File.read(Rails.root.join("lib/platform/mock_responses/update_players#{yesterday}.json")))
        else
          JSON.parse(File.read(Rails.root.join("lib/platform/mock_responses/player_id_#{player_id}_players.json")))
        end
      rescue Errno::ENOENT
        update_date.present? ? { 'id_list' => [], 'result_code' => 100 } : { 'result_code' => 805 }
      end

      # 250登録番号（250id）を指定して選手マスタを取得
      def get_player_master_by_250id(pf_250id: nil)
        JSON.parse(File.read(Rails.root.join("lib/platform/mock_responses/pf_250id_#{pf_250id}_player.json")))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # hold,hold_id_dailyを指定してプログラムリストを取得
      def get_race_table(pf_hold_id, hold_id_daily)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/pf_hold_id_#{pf_hold_id}_hold_id_daily_#{hold_id_daily}_race_table.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # entries_idを指定して出走表を取得する
      def get_race_detail(entries_id)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/entries_id_#{entries_id}_race_detail.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # pf_hold_idを指定してあっせん選手情報を取得する
      def get_mediated_players(pf_hold_id, _issue_type = 0)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/pf_hold_id_#{pf_hold_id}_mediated_player.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # update_dateを指定して開催マスタ情報（用語コード/名称）を取得する
      def get_holding_master(update_date: nil)
        JSON.parse(File.read(Rails.root.join("lib/platform/mock_responses/update_#{update_date}_holding_master.json")))
      rescue Errno::ENOENT
        update_date ? { 'id_list' => [], 'result_code' => 100 } : { 'result_code' => 801 }
      end

      # pf_hold_idを指定してタイムトライアル情報を取得する
      def get_time_trial_result(pf_hold_id)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/pf_hold_id_#{pf_hold_id}_time_trial_result.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # entries_idを指定してレース結果を取得する
      def get_race_result(entries_id)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/entries_id_#{entries_id}_race_result.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # promoter,yearを指定して年間スケジュールを取得する
      def get_annual_schedule(_promoter, year)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/annual_schedule_#{year}_result.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # player_id,hold_idを指定して選手レース戦績情報を取得する
      def get_player_race_results(player_id, hold_id)
        if hold_id.present?
          JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/player_id_#{player_id}_hold_id_#{hold_id}_race_result.json"))
        else
          JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/player_id_#{player_id}_race_result.json"))
        end
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      # player_idを指定して選手戦績情報を取得する
      def get_player_result(pf_player_id)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/player_id_#{pf_player_id}_result.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
      end

      def get_race_status(entries_id)
        JSON.parse File.read(Rails.root.join("lib/platform/mock_responses/entries_id_#{entries_id}_race_status.json"))
      rescue Errno::ENOENT
        { 'result_code' => 805 }
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
