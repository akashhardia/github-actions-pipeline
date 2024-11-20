# frozen_string_literal: true

module Admin
  # 購入履歴コントローラー
  class OrdersController < ApplicationController
    before_action :snakeize_params
    before_action :set_order, except: :export_csv

    def show
      render json: @order, serializer: Admin::OrderSerializer, action: :show, key_transform: :camel_lower
    end

    def ticket_reserves
      render json: @order.ticket_reserves, each_serializer: Admin::TicketReserveIndexSerializer, key_transform: :camel_lower
    end

    def ticket_refund
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.orders.already_returned') if @order.returned_at.present?

      PaymentTransactor.refund(@order.id)
      head :ok
    end

    def export_csv
      seat_sales = SeatSale.where(id: seat_sale_id_params_list)
      orders = []
      seat_sales.each do |seat_sale|
        orders << seat_sale.orders.includes(:payment, :campaign, :campaign_usage, :user_coupon, seat_sale: [hold_daily_schedule: :hold_daily])
                           .where(order_type: 'purchase')
                           .where(payment: { payment_progress: [:captured, :refunded] })
      end
      render json: orders.flatten, each_serializer: CsvExportOrderSerializer, action: :export_csv, key_transform: :camel_lower
    end

    def charge_status
      charge_status = NewSystem::Service.charge_status(@order.payment.charge_id)

      render json: {
        requestParams: { chargeId: @order.payment.charge_id },
        responseHttpStatus: charge_status[:response][:code].to_i,
        responseParams: charge_status.to_s
      }
    end

    private

    def set_order
      @order = Order.find(params[:id])
    end

    def seat_sale_id_params_list
      params[:seat_sale_ids]&.split(',')
    end
  end
end
