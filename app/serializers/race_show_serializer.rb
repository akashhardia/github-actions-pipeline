# frozen_string_literal: true

# レース情報のSerializerモデル
class RaceShowSerializer < ActiveModel::Serializer
  has_one :race_detail
  attributes :id, :hold_id, :race_no, :post_time, :program_no, :daily_status, :free_text

  def hold_id
    object.hold_daily_schedule.hold_daily.hold_id
  end

  def daily_status
    object.hold_daily_schedule.hold_daily.daily_status
  end
end
