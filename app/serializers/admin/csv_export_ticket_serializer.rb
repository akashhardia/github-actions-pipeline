# frozen_string_literal: true

module Admin
  # 管理画面CSVエクスポート用チケットシリアライザー
  class CsvExportTicketSerializer < ActiveModel::Serializer
    attributes :id, :user_id, :daily_no, :row, :seat_number, :order_id, :transfer_from_user_id,
               :event_date, :area_name, :unit_name, :option_title, :request_status, :coupon_id, :coupon_title,
               :purchase_order_id

    delegate :transfer_from_user_id, to: :ticket_reserve, allow_nil: true

    def event_date
      object.seat_sale.hold_daily_schedule.hold_daily.event_date
    end

    def daily_no
      object.seat_sale.hold_daily_schedule.daily_no
    end

    def area_name
      object.seat_area.master_seat_area.area_name
    end

    def unit_name
      master_seat_unit = object.master_seat_unit
      return nil if master_seat_unit.blank?

      "#{master_seat_unit.seat_type}#{master_seat_unit.unit_name}"
    end

    def option_title
      ticket_reserve&.seat_type_option&.title
    end

    def coupon_title
      ticket_reserve&.order&.coupon&.title&.gsub(',', '_') if option_title.blank?
    end

    def request_status
      object.ticket_logs.last&.request_status
    end

    delegate :order_id, to: :ticket_reserve, allow_nil: true

    def coupon_id
      ticket_reserve&.order&.user_coupon&.coupon_id if option_title.blank?
    end

    def purchase_order_id
      object.purchase_order&.id
    end

    private

    def payment
      object.payment
    end

    def ticket_reserve
      object.current_ticket_reserve || object.ticket_reserves.includes(order: :user_coupon).not_transfer_ticket_reserve.filter_ticket_reserves&.last
    end
  end
end
