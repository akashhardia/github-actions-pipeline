# frozen_string_literal: true

module V1
  module Gate
    # 入場検証APIのコントローラー
    class AdmissionController < ApplicationController
      TIMEOUT_SECONDS = 2.freeze
      before_action :set_params, only: [:verify]

      def verify
        Timeout.timeout(TIMEOUT_SECONDS) do
          return render json: { errors: [message: I18n.t('admission.ticket_not_found')] }, status: :not_found if @ticket.blank?

          # not_found以外はチケットのデータを返す
          admission_data = Serializers::Admission.create(@ticket, @user)
          response_data = { data: ActiveModelSerializers::SerializableResource.new(admission_data) }
          # エラーがあった場合は、エラーメッセージをレスポンスにマージ
          error = ticket_verification(@ticket, @user)
          response_data[:errors] = [message: I18n.t("admission.#{error}")] if error.present?

          render json: response_data, status: response_data[:errors] ? :bad_request : :ok
        end
      rescue Timeout::Error
        render json: { errors: [message: I18n.t('admission.timeout')] }, status: :request_timeout
      end

      def update_log
        Timeout.timeout(TIMEOUT_SECONDS) do
          ticket = Ticket.find_by(qr_ticket_id: log_params[:ticket_id])
          return render json: { errors: [message: I18n.t('admission.ticket_not_found')] }, status: :not_found if ticket.blank?

          # そもそもパラメータが不正の場合は、ログ作成の必要がない
          return render json: { errors: [message: I18n.t("admission.#{valid_params?[:error_message]}"), field: valid_params?[:field]] }, status: :unprocessable_entity if valid_params?

          ActiveRecord::Base.transaction do
            ticket.ticket_logs.create!(create_log_params(ticket.ticket_logs.result_true))
            # 入場時のリクエストの時は訪問時のユーザーのプロフィールを保存する
            ticket.visitor_profiles.create!(visitor_profile_params(ticket.user)) if log_params[:request_status].to_i == 1
          end

          render json: { data: true }, status: :ok
        end
      rescue Timeout::Error
        render json: { errors: [message: I18n.t('admission.timeout')] }, status: :request_timeout
      end

      def update_clean_log
        # 対象のチケットが存在しない場合はnot_found
        ticket = Ticket.find_by(qr_ticket_id: params[:ticket_id])
        return render json: { errors: [message: I18n.t('admission.ticket_not_found')] }, status: :not_found if ticket.blank?

        # 対象のチケットのログがない、またはlogのステータスがbefore_enterの場合はbad_requestを返す
        ticket_logs = ticket.ticket_logs.result_true
        return render json: { errors: [message: I18n.t('admission.ticket_cannot_clean')] }, status: :bad_request if ticket_logs.blank? || ticket_logs.last.status == 'before_enter'

        # 顔認証アプリに削除APIを投げる、失敗した場合はログを作成せずに返す
        response = ApiProvider.face_recognition.delete_face_recognition(params[:ticket_id])
        return render json: { errors: [message: I18n.t('admission.ticket_not_found')] }, status: :not_found if response.not_found?
        return render json: { errors: [message: I18n.t('admission.ticket_cannot_clean')] }, status: :bad_request unless response.ok?

        ticket.ticket_logs.create!(
          log_type: :clean_log,
          request_status: :before_enter,
          result: 'true',
          result_status: :before_enter,
          status: :before_enter,
          device_id: params[:device_id]
        )
        render json: { data: true }
      end

      private

      def ticket_verification(ticket, user)
        # チケットの入場開始時間がまだ過ぎていない、チケットがsoldではない場合に返すエラー
        return :ticket_not_available_yet if !ticket.seat_type.seat_sale.admission_available?

        if ticket.seat_type.seat_sale.admission_close?
          # ticketの入場終了時間が過ぎている場合は、log_type=2でログを作成する
          create_admission_close_log(ticket)
          return :ticket_has_expired
        end
        return :ticket_validate_failed unless ticket.correct_user?(user)

        return :ticket_has_banned if ticket.admission_disabled_at.present?

        # NGユーザをチェック
        begin
          NgUserChecker.new(user.profile.auth_code).validate!
        rescue NgUserError
          :ticket_has_banned
        rescue StandardError
          return :ticket_has_banned unless user.profile.ng_user_check?
        end
      end

      def set_params
        @ticket = Ticket.find_by(qr_ticket_id: params[:ticket_id])
        @user = User.find_by(qr_user_id: params[:user_id])
        @device_id = params[:device_id]
      end

      def log_params
        params.permit(:ticket_id, :request_status, :face_recognition, :result, :device_id)
      end

      def valid_params?
        return { error_message: :the_request_ticket_id_field_is_required, field: log_params[:request_status].blank? ? :request_status : :result } if log_params[:request_status].blank? || log_params[:result].blank?
        return { error_message: :the_value_you_have_entered_is_invalid, field: :request_status } unless TicketLog.request_statuses.value?(log_params[:request_status].to_i)
      end

      def create_admission_close_log(ticket)
        ticket_logs = ticket.ticket_logs.result_true
        ticket.ticket_logs.create!(
          log_type: 2,
          request_status: 99, # invalid_value
          result: TicketLog.results['false'],
          result_status: ticket_logs.present? ? ticket_logs.last.result_status : TicketLog.result_statuses[:before_enter],
          status: ticket_logs.present? ? ticket_logs.last.result_status : TicketLog.statuses[:before_enter],
          face_recognition: ticket_logs.present? ? ticket_logs.last.face_recognition : TicketLog.face_recognitions[:failed],
          failed_message: :the_value_you_have_entered_is_invalid,
          device_id: @device_id
        )
      end

      def visitor_profile_params(user)
        profile = user.profile
        {
          sixgram_id: user.sixgram_id,
          family_name: profile.family_name,
          given_name: profile.given_name,
          family_name_kana: profile.family_name_kana,
          given_name_kana: profile.given_name_kana,
          birthday: profile.birthday,
          zip_code: profile.zip_code,
          prefecture: profile.prefecture,
          city: profile.city,
          address_line: profile.address_line,
          address_detail: profile.address_detail,
          email: profile.email
        }
      end

      def create_log_params(ticket_logs)
        {
          log_type: 0,
          request_status: log_params[:request_status].to_i,
          result: log_params[:result].to_i,
          result_status: log_params[:request_status].to_i,
          status: ticket_logs.present? ? ticket_logs.last.result_status : 0,
          face_recognition: log_params[:face_recognition]&.to_i,
          device_id: log_params[:device_id]
        }
      end

      def pagination_hash(ticket_logs)
        {
          from: ticket_logs.prev_page,
          to: ticket_logs.next_page,
          per_page: ticket_logs.limit_value,
          total: ticket_logs.total_count,
          last_page: ticket_logs.total_pages
        }
      end
    end
  end
end
