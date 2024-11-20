# frozen_string_literal: true

module Admin
  # チケット詳細用Serializer
  class ShowTicketSerializer < TicketReserveSerializer
    attributes :id, :position, :option_title, :qr_data, :status,
               :area_name, :row, :seat_number, :event_time,
               :hold_name_jp, :daily_no, :event_date, :admission_disabled_at

    delegate :hold_name_jp, to: :hold_daily_schedule

    def daily_no
      HoldDailySchedule::DAILY_NO[hold_daily_schedule.daily_no.to_sym]
    end

    def option_title
      object.current_ticket_reserve ? object.current_ticket_reserve&.seat_type_option&.title : object.ticket_reserves.not_transfer_ticket_reserve.filter_ticket_reserves&.last&.seat_type_option&.title
    end

    def qr_data
      return nil if object.user.blank?

      %("#{object.user.qr_user_id}","#{object.qr_ticket_id}")
    end

    delegate :event_date, to: :hold_daily_schedule

    def event_time
      hold_daily_schedule.opening_display
    end

    def status
      object.ticket_logs.result_true.last&.result_status || 'before_enter'
    end

    private

    def hold_daily_schedule
      object.seat_sale.hold_daily_schedule
    end
  end
end
