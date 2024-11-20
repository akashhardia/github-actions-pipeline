# frozen_string_literal: true

module Sales
  # 予約チケットコントローラー
  class TicketReservesController < ApplicationController
    before_action :ng_user_check, only: [:show]

    def index
      ticket_reserves = TicketReserve.includes(
        ticket: [:ticket_logs, :master_seat_unit, seat_area: :master_seat_area, seat_type: :seat_sale],
        seat_type_option: :template_seat_type_option,
        order: [:payment, { seat_sale: { hold_daily_schedule: [:races, { hold_daily: :hold }] } }]
      ).admission_ticket(current_user)

      render json: ticket_reserves.filter_ticket_reserves, each_serializer: Sales::IndexTicketReserveSerializer, key_transform: :camel_lower
    end

    def show
      ticket_reserve = TicketReserve.find(params[:id])
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.ticket_reserves.ownership_not_match') if ticket_reserve.ticket.user_id != current_user.id
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.ticket_reserves.expired') if ticket_reserve.ticket.expired?

      current_user.qr_user_id_generate! unless current_user.qr_user_id?

      render json: {
        ticketReserve: ActiveModelSerializers::SerializableResource.new(ticket_reserve, serializer: Sales::ShowTicketReserveSerializer, key_transform: :camel_lower),
        profile: CaseTransform.camel_lower(current_user.profile.scoped_serializer(:full_name).serializable_hash)
      }
    end

    def transfer_uuid
      ticket = TicketReserve.find(params[:id]).ticket

      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.ticket_reserves.transfer_uuid_blank') if ticket.transfer_uuid.nil?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.ticket_reserves.ownership_not_match') if ticket.user != current_user
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.ticket_reserves.expired') if ticket.expired?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.ticket_reserves.already_entered') unless ticket.before_enter?

      render json: { transferUuid: ticket.transfer_uuid }
    end
  end
end
