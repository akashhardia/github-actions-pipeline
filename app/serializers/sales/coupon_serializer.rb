# frozen_string_literal: true

module Sales
  # salesクーポン関連のシリアルライザー
  class CouponSerializer < ActiveModel::Serializer
    attributes :id, :title, :rate, :note, :available_end_at
  end
end
