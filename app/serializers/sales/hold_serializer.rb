# frozen_string_literal: true

module Sales
  # 開催シリアライザー
  class HoldSerializer < ActiveModel::Serializer
    attributes :id, :promoterYear, :period, :round
  end
end
