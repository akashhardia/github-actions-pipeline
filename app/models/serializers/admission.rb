# frozen_string_literal: true

module Serializers
  # 入場API用のSerializerモデル
  class Admission < ActiveModelSerializers::Model
    attributes :id, :user_id, :status,
               :created_at, :updated_at

    def self.create(ticket, user)
      attributes = { id: ticket.qr_ticket_id,
                     user_id: user&.qr_user_id,
                     status: ticket.ticket_logs.result_true.last&.result_status_before_type_cast || 0, # ticket_logがない場合は 0 を返す
                     created_at: ticket.created_at.iso8601,
                     updated_at: ticket.updated_at.iso8601 }

      new(attributes)
    end

    def ticket
      target_ticket = Ticket.find_by(qr_ticket_id: id)
      user = User.find_by(qr_user_id: user_id)
      ticket_reserves = TicketReserve.includes(seat_type_option: :template_seat_type_option, order: :payment).where(ticket_id: target_ticket.id, orders: { user_id: user&.id }, transfer_at: nil)
      time = target_ticket.hold_daily_schedule.opening_display
      hold_datetime = target_ticket.hold_daily.event_date.strftime("%Y-%m-%d #{time}")
      { hold_datetime: hold_datetime, seat_type_name: target_ticket.coordinate_seat_type_name, seat_number: target_ticket.coordinate_seat_number, seat_type_option: ticket_reserves.filter_ticket_reserves&.last&.seat_type_option&.title }
    end
  end
end
