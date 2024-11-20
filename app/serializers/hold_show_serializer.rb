# frozen_string_literal: true

# 開催詳細のシリアライザ
class HoldShowSerializer < ActiveModel::Serializer
  attributes :id, :pf_hold_id, :track_code, :hold_name_jp, :first_day
end
