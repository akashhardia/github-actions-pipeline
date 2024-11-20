# frozen_string_literal: true

module Admin
  # 座席エリアテンプレートコントローラー
  class TemplateSeatAreasController < ApplicationController
    def index
      template_seat_sale = TemplateSeatSale.preload(template_seat_areas: [{ template_seats: :master_seat }, :master_seat_area]).find(params[:template_seat_sale_id])

      render json: template_seat_sale.template_seat_areas, each_serializer: Admin::IndexTemplateSeatAreaSerializer, key_transform: :camel_lower
    end

    def show
      template_seat_area = TemplateSeatArea.preload(template_seats: [master_seat: :master_seat_unit]).find(params[:id])
      template_seats = template_seat_area.template_seats

      render json: template_seats, each_serializer: TemplateSeatSerializer, key_transform: :camel_lower
    end
  end
end
