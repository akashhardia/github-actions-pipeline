# frozen_string_literal: true

module Sales
  # 所持チケット詳細用Serializer
  class ShowTicketReserveSerializer < TicketReserveSerializer
    attributes :position, :discounted_price, :option_title, :coupon, :campaign, :qr_data,
               :area_name, :position, :row, :seat_number,
               :daily_no, :event_date,
               :sales_type, :unit_type, :unit_name, :sub_code,
               :promoter_year, :period, :round, :high_priority_event_code,
               :track_name, :entrance_name, :open_at, :start_at

    delegate :seat_area, :area_name, :position, :row, :seat_number, :sales_type, :sub_code, :sub_code, to: :ticket
    delegate :daily_no, :event_date, :high_priority_event_code, to: :hold_daily_schedule
    delegate :promoter_year, :period, :round, to: :hold_daily
    delegate :track_name, to: :seat_area
    delegate :entrance_name, to: :seat_area

    def discounted_price
      discount = object.seat_type_option&.price.present? ? object.seat_type_option.price : 0
      object.ticket.price + discount
    end

    def option_title
      object.seat_type_option.present? ? object.seat_type_option.title : '-'
    end

    def coupon
      return unless object.order.coupon&.template_coupon

      {
        title: object.order.coupon.template_coupon.title,
        rate: object.order.coupon.template_coupon.rate
      }
    end

    def campaign
      return unless object.order.campaign

      {
        title: object.order.campaign.title,
        discount_rate: object.order.campaign.discount_rate
      }
    end

    def qr_data
      %("#{object.order.user.qr_user_id}","#{object.ticket.qr_ticket_id}")
    end

    def hold_date
      hold_daily_schedule.event_date
    end

    def unit_type
      ticket.master_seat_unit&.seat_type
    end

    def unit_name
      ticket.master_seat_unit&.unit_name
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

    def hold_daily
      object.order.seat_sale.hold_daily
    end

    def hold
      object.order.seat_sale.hold_daily.hold
    end

    def ticket
      object.ticket
    end
  end
end
