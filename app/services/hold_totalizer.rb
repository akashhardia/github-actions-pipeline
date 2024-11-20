# frozen_string_literal: true

# holdインスタンスを引数に設定し初期化
class HoldTotalizer
  attr_reader :hold

  def initialize(hold)
    @hold = hold
  end

  def hold_dailies
    @hold_dailies ||= hold.hold_dailies
  end

  def filter_by_date(date)
    @hold_dailies = hold_dailies.where(event_date: date)
  end

  def order_total_price
    hold_dailies.sum do |hold_daily|
      HoldDailyTotalizer.new(hold_daily).order_total_price
    end
  end

  def order_total_number
    hold_dailies.sum do |hold_daily|
      HoldDailyTotalizer.new(hold_daily).order_total_number
    end
  end
end
