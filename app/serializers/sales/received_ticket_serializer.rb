# frozen_string_literal: true

module Sales
  # チケット譲渡受け取り用Serializer
  class ReceivedTicketSerializer < TicketSerializer
    attributes :area_name, :event_date, :daily_no,
               :position, :sales_type, :unit_type, :unit_name, :sub_code, :transfer_from_user_name,
               :promoter_year, :period, :round, :high_priority_event_code, :open_at, :start_at

    delegate :event_date, :daily_no, :high_priority_event_code, to: :hold_daily_schedule
    delegate :promoter_year, :period, :round, to: :hold_daily

    def unit_type
      object.master_seat_unit&.seat_type
    end

    def unit_name
      object.master_seat_unit&.unit_name
    end

    def transfer_from_user_name
      User.find(object.user_id).profile.full_name if object.user_id.present?
    end

    def open_at
      hold_daily_schedule.opening_display
    end

    def start_at
      hold_daily_schedule.start_display
    end

    private

    def hold_daily_schedule
      object.seat_area.seat_sale.hold_daily_schedule
    end

    def hold_daily
      object.seat_area.seat_sale.hold_daily
    end
  end
end
