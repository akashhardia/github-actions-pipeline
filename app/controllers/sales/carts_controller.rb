# frozen_string_literal: true

module Sales
  # 座席選択コントローラー
  class CartsController < ApplicationController
    before_action :snakeize_params

    def create
      cart = Cart.new(current_user)
      error = cart.replace_tickets(params[:order], params[:coupon_id], params[:campaign_code])
      error_message = I18n.t("custom_errors.orders.#{error}") if error
      result = error.present? ? {} : cart.purchase_order.to_response_hash

      render json: { succeed: error.nil?, result: result, error: error_message }
    end

    def seat_type_options_select
      cart = Cart.new(current_user)
      raise SeatSalesFlowError, I18n.t('custom_errors.orders.cart_is_empty') if cart.ticket_orders.value.blank?

      render json: cart.purchase_order.to_response_hash
    end

    def purchase_confirmation
      cart = Cart.new(current_user)

      render json: cart.purchase_order.to_response_hash
    end

    def purchase_preview
      cart = Cart.new(current_user)

      render json: { cart: cart.purchase_order.to_response_hash, coupons: cart_available_coupons(cart) }
    end

    private

    def cart_available_coupons(cart)
      ids_params = {
        hold_daily_schedule_id: cart.hold_daily_schedule.id,
        master_seat_type_ids: cart.tickets.map { |t| t.seat_type.master_seat_type.id }.uniq
      }
      cart_coupon = current_user.coupons.find_by(id: cart.orders[:coupon_id])
      total_user_coupons = current_user.coupons.available_to_user(current_user, Time.zone.now, cart_coupon)
      available_coupons = total_user_coupons.present? ? AvailableCouponsForPurchase.new(ids_params, total_user_coupons.includes(:template_coupon, :coupon_hold_daily_conditions, :coupon_seat_type_conditions)).available_coupons : []
      available_coupons.sort_by(&:rate).reverse!.map do |coupon|
        {
          id: coupon.id,
          title: coupon.title,
          rate: coupon.rate,
          note: coupon.note
        }
      end
    end
  end
end
