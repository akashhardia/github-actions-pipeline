# frozen_string_literal: true

require 'active_model'

module Sales
  # クーポンコントローラー
  class CouponsController < ApplicationController
    # クーポン一覧
    def index
      coupons = current_user.coupons.available_to_user(current_user, Time.zone.now).includes(:template_coupon).page(params[:page] || 1).per(6)

      pagination = resources_with_pagination(coupons)
      serialized_coupons = ActiveModelSerializers::SerializableResource.new(coupons, each_serializer: Sales::CouponSerializer, key_transform: :camel_lower)
      render json: { coupons: serialized_coupons, pagination: pagination }
    end

    # チケット購入時、利用可能なクーポン一覧を提供
    def available_coupons
      # paramsでhold_daily_schedule_idとmaster_seat_type_id(配列)が送られてくる
      # {
      #   "hold_daily_schedule_id"=>"1",
      #   "master_seat_type_ids"=>["1", "2"]
      # }
      total_user_coupons = current_user.coupons.includes(:template_coupon, :coupon_hold_daily_conditions, :coupon_seat_type_conditions).available_to_user(current_user, Time.zone.now)
      available_coupons = total_user_coupons.present? ? AvailableCouponsForPurchase.new(params, total_user_coupons).available_coupons : []
      render json: available_coupons.sort_by(&:rate).reverse!, each_serializer: Sales::CouponSerializer, key_transform: :camel_lower
    end
  end
end
