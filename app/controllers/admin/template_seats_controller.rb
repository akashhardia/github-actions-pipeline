# frozen_string_literal: true

module Admin
  # チケットコントローラー
  class TemplateSeatsController < ApplicationController
    before_action :snakeize_params
    before_action :set_template_seats, only: [:stop_selling, :release_from_stop_selling]

    def stop_selling
      ActiveRecord::Base.transaction do
        @template_seats.each(&:stop_selling!)
      end

      render json: @template_seats.reload, each_serializer: TemplateSeatSerializer, key_transform: :camel_lower
    end

    def release_from_stop_selling
      ActiveRecord::Base.transaction do
        @template_seats.each(&:release_from_stop_selling!)
      end

      render json: @template_seats.reload, each_serializer: TemplateSeatSerializer, key_transform: :camel_lower
    end

    private

    def set_template_seats
      @template_seats = TemplateSeat.where(id: params[:template_seat_ids]).includes(:template_seat_type, :template_seat_area, [master_seat: :master_seat_unit])
      raise CustomError.new(http_status: :not_found, code: 'not_found'), I18n.t('custom_errors.template_seats.ticket_not_found') unless @template_seats.size == params[:template_seat_ids].size
    end
  end
end
