# frozen_string_literal: true

# クーポン関連モデルクリエーター
class AvailableCouponsForPurchase
  attr_reader :hold_daily_schedule_id, :master_seat_type_ids, :total_user_coupons

  def initialize(params, total_user_coupons)
    @hold_daily_schedule_id = params[:hold_daily_schedule_id] && params[:hold_daily_schedule_id]&.to_i
    @master_seat_type_ids = params[:master_seat_type_ids] && params[:master_seat_type_ids]&.map(&:to_i)
    @total_user_coupons = total_user_coupons
  end

  def available_coupons
    total_user_coupons.select do |coupon|
      target_hold_daily_schedule_ids = coupon.coupon_hold_daily_conditions.map(&:hold_daily_schedule_id)
      target_master_seat_type_ids = coupon.coupon_seat_type_conditions.map(&:master_seat_type_id)
      next false if target_hold_daily_schedule_ids.present? && !target_hold_daily_schedule_ids.include?(hold_daily_schedule_id)

      target_master_seat_type_ids.blank? || target_master_seat_type_ids.any? { |allow_id| master_seat_type_ids.include?(allow_id) }
    end
  end
end
