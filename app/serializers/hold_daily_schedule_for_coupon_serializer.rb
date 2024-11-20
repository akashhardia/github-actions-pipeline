# frozen_string_literal: true

# クーポン新規作成画面で必要な情報を取得
class HoldDailyScheduleForCouponSerializer < ActiveModel::Serializer
  attributes :id, :name

  # フロント側で表示の複数選択可の
  def name
    wd = %w[日 月 火 水 木 金 土].freeze
    daily_no_display = HoldDailySchedule::DAILY_NO[object.daily_no.to_sym]

    event_date_display = object.event_date.strftime("%Y/%m/%d(#{wd[object.event_date.wday]})")
    "#{daily_no_display} #{event_date_display} #{object.hold_name_jp}"
  end
end
