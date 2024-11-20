# frozen_string_literal: true

module Admin
  # 管理画面の購入履歴
  class BulkRefundResultSerializer < ActiveModel::Serializer
    attributes :id, :total_price, :created_at, :payment_status, :returned_at, :used_coupon, :refund_error_message

    def payment_status
      object.payment&.payment_progress
    end

    def used_coupon
      object.coupon.present? ? "#{object.coupon.title}(ID: #{object.coupon.id})" : '無し'
    end
  end
end
