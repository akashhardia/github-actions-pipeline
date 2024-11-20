# frozen_string_literal: true

# hold_daily_scheduleインスタンスを引数に設定し初期化
class HoldDailyScheduleTotalizer
  attr_reader :hold_daily_schedule

  def initialize(hold_daily_schedule)
    @hold_daily_schedule = hold_daily_schedule
  end

  def order_total_price
    available_seat_sale.sum do |seat_sale|
      # 新規購入で且つ、返品されていないorderが対象
      seat_sale.orders.accounting_target.sum(:total_price)
    end
  end

  def order_total_number
    available_seat_sale.sum do |seat_sale|
      # 新規購入で且つ、返品されていないorderに紐づくticket_reserveが対象
      seat_sale.orders.accounting_target.sum do |order|
        order.ticket_reserves.count
      end
    end
  end

  private

  def available_seat_sale
    hold_daily_schedule.seat_sales.select(&:accounting_target?)
  end
end
