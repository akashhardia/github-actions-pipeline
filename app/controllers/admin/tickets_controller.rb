# frozen_string_literal: true

module Admin
  # チケットコントローラー
  class TicketsController < ApplicationController
    before_action :snakeize_params
    before_action :set_tickets, only: [:stop_selling, :release_from_stop_selling, :transfer, :transfer_cancel]
    before_action :set_ticket, only: [:show, :before_enter, :update_admission_disabled_at]

    def index
      raise CustomError.new(http_status: :bad_request, code: 'qr_ticket_id_error'), I18n.t('custom_errors.ticket.qr_ticket_id_required') if params[:qr_ticket_id].blank?

      condition = ActiveRecord::Type::Boolean.new.cast(params[:today]) ? { admission_available_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day } : nil
      seat_sale_ids = SeatSale.where(condition).ids

      # 前方一致でチケットを取得
      tickets = Ticket.includes(current_ticket_reserve: :seat_type_option, seat_area: { seat_sale: { hold_daily_schedule: { hold_daily: :hold } } }).where(seat_sale: { id: seat_sale_ids }).where('qr_ticket_id LIKE ?', "#{params[:qr_ticket_id]}%")

      raise CustomError.new(http_status: :bad_request, code: 'qr_ticket_id_error'), I18n.t('custom_errors.ticket.not_found') if tickets.blank?

      render json: tickets, each_serializer: Admin::TicketIndexSerializer, key_transform: :camel_lower
    end

    def info
      ticket = Ticket.find(params[:id])

      render json: { qrUserId: ticket.user&.qr_user_id }
    end

    def stop_selling
      ActiveRecord::Base.transaction do
        @tickets.includes(:master_seat_unit).each(&:stop_selling!)
      end

      render json: @tickets.reload, each_serializer: Admin::AdminTicketSerializer, key_transform: :camel_lower
    end

    def release_from_stop_selling
      ActiveRecord::Base.transaction do
        @tickets.includes(:master_seat_unit).each(&:release_from_stop_selling!)
      end

      render json: @tickets.reload, each_serializer: Admin::AdminTicketSerializer, key_transform: :camel_lower
    end

    def transfer
      ActiveRecord::Base.transaction do
        @tickets.includes(:master_seat_unit).each(&:not_for_sale_ticket_uuid_generate!)
      end

      render json: @tickets.reload, each_serializer: Admin::AdminTicketSerializer, key_transform: :camel_lower
    end

    def transfer_cancel
      ActiveRecord::Base.transaction do
        @tickets.includes(:master_seat_unit).each(&:cancel_admin_transfer!)
      end

      render json: @tickets.reload, each_serializer: Admin::AdminTicketSerializer, key_transform: :camel_lower
    end

    def show
      # paramsの有無でシリアライザ切り替え
      serializer = params[:detail].present? ? Admin::DetailTicketSerializer : Admin::ShowTicketSerializer
      render json: @ticket, serializer: serializer, key_transform: :camel_lower
    end

    def reserve_status
      ticket_reserve_status = TicketReserve.includes([:ticket, :order]).where(ticket: { id: params[:id] }).order(id: 'DESC')
      render json: ticket_reserve_status, each_serializer: Admin::TicketReserveStatusSerializer, key_transform: :camel_lower
    end

    def logs
      ticket_logs = TicketLog.includes([:ticket]).where(ticket: { id: params[:id] }).order(id: 'DESC')
      render json: ticket_logs, key_transform: :camel_lower
    end

    # チケットを未入場にする
    def before_enter
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.ticket.qr_ticket_id_blank') if @ticket.qr_ticket_id.blank?

      # 対象のチケットのログがない、またはlogのステータスがbefore_enterの場合は何もしない
      ticket_logs = @ticket.ticket_logs.result_true
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.ticket.status_is_before_enter') if ticket_logs.blank? || ticket_logs.last.result_status == 'before_enter'

      # 顔認証アプリに削除APIを投げる、失敗した場合はログを作成せずに返す
      response = ApiProvider.face_recognition.delete_face_recognition(@ticket.qr_ticket_id)
      raise CustomError.new(http_status: :not_found, code: 'not_found'), I18n.t('custom_errors.ticket.face_recognition_not_found') if response.not_found?
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.ticket.fail_to_delete_face_recognition') unless response.ok?

      # device_idなしで未入場のチケットログを作成する
      @ticket.ticket_logs.create!(
        log_type: :clean_log,
        request_status: :before_enter,
        result: 'true',
        result_status: :before_enter,
        status: :before_enter,
        device_id: nil
      )

      render json: { ticketStatus: @ticket.ticket_logs.last.result_status }
    end

    def update_admission_disabled_at
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.ticket.qr_ticket_id_blank') if @ticket.qr_ticket_id.blank?
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.ticket.already_disabled') if params[:update_action] == 'disable' && @ticket.admission_disabled_at.present?
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.ticket.already_enabled') if params[:update_action] == 'enable' && @ticket.admission_disabled_at.blank?

      # disableの場合は、admission_disabled_atを埋める。enableの場合はadmission_disabled_atをnilにする
      @ticket.update!(admission_disabled_at: params[:update_action] == 'disable' ? Time.zone.now : nil)

      render json: @ticket.admission_disabled_at
    end

    def export_csv
      tickets = Ticket.sold.includes(:ticket_logs, :master_seat_unit, seat_area: [:master_seat_area, [seat_sale: [hold_daily_schedule: :hold_daily]]], ticket_reserves: :order, purchase_ticket_reserve: :order, current_ticket_reserve: [:seat_type_option, [order: [user_coupon: [coupon: :template_coupon]]]])
                      .where(admission_disabled_at: nil, order: { seat_sale_id: seat_sale_id_params_list }).order('order.id').uniq

      render json: tickets, each_serializer: CsvExportTicketSerializer, action: :export_csv, key_transform: :camel_lower
    end

    private

    def set_tickets
      @tickets = Ticket.where(id: params[:ticket_ids]).includes([:seat_type, { seat_area: :master_seat_area }])
      raise CustomError.new(http_status: :not_found, code: 'not_found'), I18n.t('custom_errors.ticket.not_exist') unless @tickets.size == params[:ticket_ids].size
    end

    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    def seat_sale_id_params_list
      params[:seat_sale_ids].split(',')
    end
  end
end
