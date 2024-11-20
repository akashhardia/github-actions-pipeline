# frozen_string_literal: true

# 開催デイリー一覧のシリアライザ
class HoldDailyIndexSerializer < ApplicationSerializer
  attributes :id, :hold_id_daily, :event_date, :hold_daily, :hold_id,
             :daily_branch, :program_count, :race_count, :daily_status,
             :created_at, :updated_at

  has_many :hold_daily_schedules, serializer: HoldDailyScheduleIndexSerializer, if: :relation?

  def daily_status
    I18n.t("activerecord.attributes.hold_daily.daily_status.#{object.daily_status}")
  end
end
