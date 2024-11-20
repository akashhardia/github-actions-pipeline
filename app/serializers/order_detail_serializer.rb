# frozen_string_literal: true

# 購入履歴詳細のSerializerモデル
class OrderDetailSerializer < ActiveModel::Serializer
  attributes :hold_daily_schedule, :ticket_list, :coupon, :campaign, :total_price, :payment, :area_name, :position, :sales_type, :unit_type, :unit_name, :returned_at

  def hold_daily_schedule
    {
      dailyNo: object.hold_daily_schedule.daily_no,
      eventDate: object.hold_daily_schedule.event_date,
      dayOfWeek: object.hold_daily_schedule.event_date.wday,
      promoter_year: object.hold_daily_schedule.hold_daily.promoter_year,
      period: object.hold_daily_schedule.hold_daily.period,
      round: object.hold_daily_schedule.hold_daily.round,
      high_priority_event_code: object.hold_daily_schedule.high_priority_event_code,
      open_at: object.hold_daily_schedule.opening_display,
      start_at: object.hold_daily_schedule.start_display
    }
  end

  def coupon
    return unless object.coupon

    {
      title: object.coupon.title,
      rate: object.coupon.rate
    }
  end

  def campaign
    return unless object.campaign

    {
      title: object.campaign.title,
      discount_rate: object.campaign.discount_rate
    }
  end
end
