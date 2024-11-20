# frozen_string_literal: true

module Serializers
  # order詳細用のSerializerモデル
  class OrderDetail < ActiveModelSerializers::Model
    attributes :hold_daily_schedule, :ticket_list, :coupon, :campaign, :total_price, :payment, :area_name, :ticket_reserves, :position, :sales_type, :unit_type, :unit_name, :returned_at

    class << self
      def create(order)
        ticket = order.tickets.first
        ticket_reserves = order.ticket_reserves

        attributes =
          {
            hold_daily_schedule: order.seat_sale.hold_daily_schedule,
            ticket_reserves: ticket_reserves,
            ticket_list: ticket_list_generate(order.tickets, ticket_reserves),
            coupon: order.coupon&.template_coupon,
            campaign: order.campaign,
            total_price: order.total_price,
            # TODO: paymentについては、他の支払方法があるのかわかるまで固定
            payment: 'ご登録済みクレジットカード',
            area_name: ticket.area_name,
            position: ticket.seat_area.master_seat_area.position,
            sales_type: ticket.sales_type,
            unit_type: ticket.master_seat_unit&.seat_type,
            unit_name: ticket.master_seat_unit&.unit_name,
            returned_at: order.returned_at
          }

        new(attributes)
      end

      private

      def ticket_list_generate(tickets, ticket_reserves)
        return [] if tickets.blank?

        tickets.each_with_object([]) do |ticket, arr|
          # TODO: 単独の席名については、とりあえずarea+row+seat_numberであるcoordinateを返す
          # 購入履歴詳細画像を見ると席単独の金額は必要ない
          arr << { row: ticket.row, seatNumber: ticket.seat_number, optionTitle: seat_type_option(ticket, ticket_reserves)&.title }
        end
      end

      def seat_type_option(ticket, ticket_reserves)
        seat_type_option_id = ticket_reserves.find { |reserve| reserve.ticket_id == ticket.id }&.seat_type_option_id
        ticket.seat_type.seat_type_options.find(seat_type_option_id) if seat_type_option_id.present?
      end
    end
  end
end
