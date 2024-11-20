# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_daily_schedules
#
#  id            :bigint           not null, primary key
#  daily_no      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_daily_id :bigint           not null
#
# Indexes
#
#  index_hold_daily_schedules_on_hold_daily_id  (hold_daily_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_id => hold_dailies.id)
#
class HoldDailyScheduleSerializer < ActiveModel::Serializer
  attributes :id, :daily_branch, :daily_no, :daily_status, :event_date,
             :hold_daily, :hold_id_daily, :program_count, :race_count,
             :hold_id, :day_of_week, :available, :sales_status, :promoter_year,
             :period, :round, :high_priority_event_code, :open_at, :start_at

  def hold_daily
    object.column_hold_daily
  end

  # 曜日
  def day_of_week
    object.event_date.wday
  end

  # 開催名称
  delegate :sales_status, to: :object

  # 購入可能かどうかチェック
  # true->販売可能 false->不可能
  def available
    object.available?
  end

  def open_at
    object.opening_display
  end

  def start_at
    object.start_display
  end
end
