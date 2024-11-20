# frozen_string_literal: true

module Sales
  # 開催スケジュールシリアルライザー
  class HoldDailyScheduleSerializer < ActiveModel::Serializer
    attributes :id, :daily_no, :available, :sales_status, :high_priority_event_code, :in_stock, :day_night_display, :open_at, :start_at

    # 購入可能かどうかチェック
    # true->販売可能 false->不可能
    def available
      object.available?
    end

    # チケットが売り切れかチェック
    def in_stock
      object.available_seat_sale.tickets.exists?(status: :available)
    end

    delegate :day_night_display, to: :object

    def open_at
      object.opening_display
    end

    def start_at
      object.start_display
    end
  end
end
