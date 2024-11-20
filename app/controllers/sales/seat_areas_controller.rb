# frozen_string_literal: true

module Sales
  # 座席エリアコントローラー
  class SeatAreasController < ApplicationController
    def show
      seat_area = SeatArea.find(params[:id])
      seat_sale = seat_area.seat_sale
      tickets = seat_area.tickets

      error = check_for_saleability(seat_sale, seat_area, tickets)
      error_message = I18n.t("custom_errors.orders.#{error}") if error
      raise SeatSalesFlowError, error_message if error_message

      serialized_tickets = ActiveModelSerializers::SerializableResource.new(tickets, key_transform: :camel_lower, current_user_id: current_user.id)
      serialized_seat_area = ActiveModelSerializers::SerializableResource.new(seat_area, key_transform: :camel_lower)
      serialized_hold_daily_schedule = ActiveModelSerializers::SerializableResource.new(seat_sale.hold_daily_schedule, key_transform: :camel_lower)

      cart = Cart.new(current_user)
      cart_tickets = ActiveModelSerializers::SerializableResource.new(tickets.where(id: cart.cart_ticket_ids), key_transform: :camel_lower)

      ticket = tickets.includes([:master_seat_unit]).first

      render json: {
        tickets: serialized_tickets,
        holdDailySchedule: serialized_hold_daily_schedule,
        seatArea: serialized_seat_area,
        cartTickets: cart_tickets,
        salesType: ticket.sales_type,
        unitType: ticket.master_seat_unit&.seat_type,
        unitName: ticket.master_seat_unit&.unit_name
      }
    end

    private

    def check_for_saleability(seat_sale, seat_area, tickets)
      return :unapproved_sales unless seat_sale.on_sale?
      return :sale_term_outside unless seat_sale.check_sales_schedule?
      return :area_display_not_permitted unless seat_area.displayable?
      return :ticket_not_available unless tickets.any?(&:available?)
    end
  end
end
