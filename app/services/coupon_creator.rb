# frozen_string_literal: true

# クーポン関連モデルクリエーター
class CouponCreator
  attr_reader :template_coupon_params, :coupon_params, :hold_daily_schedule_ids, :master_seat_type_ids

  def initialize(params)
    @template_coupon_params = JSON.parse(params[:templateCoupon])
    @coupon_params = JSON.parse(params[:coupon])
    @hold_daily_schedule_ids = JSON.parse(params[:holdDailyScheduleIds])
    @master_seat_type_ids = JSON.parse(params[:masterSeatTypeIds])
  end

  def create_coupon!
    ActiveRecord::Base.transaction do
      template_coupon = create_template_coupon(template_coupon_params)
      coupon = create_coupon(coupon_params, template_coupon)
      create_coupon_hold_daily_conditions(hold_daily_schedule_ids, coupon)
      create_coupon_seat_type_conditions(master_seat_type_ids, coupon)
      coupon
    end
  end

  private

  def create_template_coupon(template_coupon_params)
    TemplateCoupon.create!(title: template_coupon_params['title'],
                           rate: template_coupon_params['rate'],
                           note: template_coupon_params['note'])
  end

  def create_coupon(coupon_params, template_coupon)
    raise CustomError.new(http_status: :bad_request, code: 'not_before_available_end_at'), I18n.t('custom_errors.coupons.not_before_available_end_at') if DateTime.parse(coupon_params['availableEndAt']) < Time.zone.now

    Coupon.create!(template_coupon: template_coupon, available_end_at: coupon_params['availableEndAt'])
  end

  def create_coupon_hold_daily_conditions(hold_daily_schedule_ids, coupon)
    hold_daily_schedules = HoldDailySchedule.where(id: hold_daily_schedule_ids)
    raise CustomError.new(http_status: :not_found, code: 'not_found_hold_daily'), I18n.t('custom_errors.coupons.not_found_hold_daily') unless hold_daily_schedules.size == hold_daily_schedule_ids.size

    coupon_hold_daily_conditions = hold_daily_schedules.map do |hold_daily_schedule|
      CouponHoldDailyCondition.new(coupon: coupon, hold_daily_schedule: hold_daily_schedule)
    end

    CouponHoldDailyCondition.import! coupon_hold_daily_conditions
  end

  def create_coupon_seat_type_conditions(master_seat_type_ids, coupon)
    master_seat_types = MasterSeatType.where(id: master_seat_type_ids)
    raise CustomError.new(http_status: :not_found, code: 'not_found_seat_type'), I18n.t('custom_errors.coupons.not_found_seat_type') unless master_seat_types.size == master_seat_type_ids.size

    coupon_seat_type_conditions = master_seat_types.map do |master_seat_type|
      CouponSeatTypeCondition.new(coupon: coupon, master_seat_type: master_seat_type)
    end

    CouponSeatTypeCondition.import! coupon_seat_type_conditions
  end
end
