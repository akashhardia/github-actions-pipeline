# frozen_string_literal: true

module Sales
  # 所持チケット一覧用Serializer
  class IndexTicketReserveSerializer < TicketReserveSerializer
    attributes :transfer_status, :event_date,
               :daily_no,
               :area_name, :row, :seat_number,
               :position, :sales_type, :unit_type, :unit_name, :sub_code,
               :promoter_year, :period, :round, :high_priority_event_code, :before_enter,
               :open_at, :start_at

    delegate :area_name, :position, :row, :seat_number, :sales_type, :sub_code, to: :ticket
    delegate :hold_name_jp, :daily_no, :event_date, :high_priority_event_code, to: :hold_daily_schedule
    delegate :promoter_year, :period, :round, to: :hold_daily

    def transfer_status
      return 'done' if object.transfer_at.present? # 譲渡完了
      return 'doing' if ticket.transfer_uuid.present? # 譲渡中

      'notDone' # 譲渡処理をしていない
    end

    def unit_type
      ticket.master_seat_unit&.seat_type
    end

    def unit_name
      ticket.master_seat_unit&.unit_name
    end

    def before_enter
      ticket.before_enter?
    end

    def open_at
      hold_daily_schedule.opening_display
    end

    def start_at
      hold_daily_schedule.start_display
    end

    private

    def hold_daily_schedule
      object.order.seat_sale.hold_daily_schedule
    end

    def ticket
      object.ticket
    end

    def hold_daily
      object.order.seat_sale.hold_daily
    end
  end
end
