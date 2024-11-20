# frozen_string_literal: true

module Admin
  # 座席エリアコントローラー
  class SeatAreasController < ApplicationController
    def index
      seat_sale = SeatSale.preload(seat_areas: [:tickets, :master_seat_area]).find(params[:seat_sale_id])

      render json: seat_sale.seat_areas, each_serializer: Admin::IndexSeatAreaSerializer, key_transform: :camel_lower
    end

    def show
      seat_area = SeatArea.find(params[:id])
      tickets = seat_area.tickets.includes(:master_seat_unit)

      render json: tickets, each_serializer: Admin::AdminTicketSerializer, key_transform: :camel_lower
    end
  end
end
