# frozen_string_literal: true

# hold_dailyインスタンスを引数に設定し初期化
class HoldDailyTotalizer
  attr_reader :hold_daily

  def initialize(hold_daily)
    @hold_daily = hold_daily
  end

  def hold_daily_schedules
    @hold_daily_schedules ||= hold_daily.hold_daily_schedules
  end

  def order_total_price
    hold_daily_schedules.sum do |hold_daily_schedule|
      HoldDailyScheduleTotalizer.new(hold_daily_schedule).order_total_price
    end
  end

  def order_total_number
    hold_daily_schedules.sum do |hold_daily_schedule|
      HoldDailyScheduleTotalizer.new(hold_daily_schedule).order_total_number
    end
  end
end
