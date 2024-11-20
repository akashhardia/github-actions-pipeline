# frozen_string_literal: true

module V1
  module Portal250
    # 250PFからの変更通知を受けるコントローラ
    class NotificationsController < ApplicationController
      def odds
        PlatformNotificationSync.odds_creator!(odds_params)

        render json: { result_code: 100 }
      rescue StandardError
        # TODO: エラー時に返すコードについては250PFとすり合わせ必要
        render json: { result_code: 600 }
      end

      def vote
        PlatformNotificationSync.close_time_update!(vote_params)

        render json: { result_code: 100 }
      rescue StandardError
        # TODO: エラー時に返すコードについては250PFとすり合わせ必要
        render json: { result_code: 600 }
      end

      def payoff
        PlatformNotificationSync.payoff_creator!(payoff_params)

        render json: { result_code: 100 }
      rescue StandardError
        # TODO: エラー時に返すコードについては250PFとすり合わせ必要
        render json: { result_code: 600 }
      end

      def holding
        id_list = hold_params[:id_list]

        case hold_params[:type_id].to_i
        when 1 # hold_idでカレンダーAPIをリクエストして、更新または登録をする
          PlatformSync.hold_bulk_update!(get_params_list(id_list))
        when 2 # あっせん選手をhold_idでリクエストし登録または更新をする
          PlatformSync.mediated_players_upsert!(get_params(id_list, 'hold_id'))
        when 3 # race_detail関連について取得しに行き登録、更新する
          PlatformSync.race_detail_get(get_params(id_list, 'hold_id'), get_params(id_list, 'hold_id_daily'))
        when 4 # race_detail関連について取得しに行き登録、更新する
          PlatformSync.race_detail_upsert!(get_params(id_list, 'entries_id'))
        when 5 # race_result関連について取得しに行き登録する
          PlatformSync.race_result_get(get_params(id_list, 'entries_id'))
        when 6, 7, 8, 9 # hold_idを指定して、Hold関連を更新する
          PlatformSync.hold_update!(hold_id: get_params(id_list, 'hold_id'))
        when 10 # タイムトライアル関連について取得しに行き更新する
          PlatformSync.time_trial_result_upsert!(get_params(id_list, 'hold_id'))
        when 11 # id_listを考慮せず、昨日の日付で更新する
          PlatformSync.player_update(Date.yesterday.strftime('%Y%m%d'), nil)
        else
          # type_idが想定外の場合
          return render json: { result_code: 600 }
        end

        render json: { result_code: 100 }
      rescue StandardError
        # TODO: エラー時に返すコードについては250PFとすり合わせ必要
        render json: { result_code: 600 }
      end

      private

      def odds_params
        params.permit(:entries_id, :odds_time, :fixed, odds_list: [:vote_type, :odds_count, odds: [:tip1, :tip2, :tip3, :odds_val, :odds_max_val]])
      end

      def vote_params
        params.permit(:status, :hold_id, :hold_id_daily, entries_id_list: [:entries_id, :race_no, :close_time])
      end

      def payoff_params
        params.permit(:entries_id, :race_status, rank: [], payoff_list: [:payoff_type, :vote_type, :tip1, :tip2, :tip3, :payoff])
      end

      def hold_params
        params.permit(:type_id, id_list: [:key, :value])
      end

      def get_params(id_list, key)
        target = id_list.find { |h| h[:key] == key }
        target&.fetch(:value)
      end

      def get_params_list(id_list)
        id_list.map { |pa| pa[:value] }
      end
    end
  end
end
