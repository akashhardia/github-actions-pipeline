# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id               :bigint           not null, primary key
#  captured_at      :datetime
#  payment_progress :integer          default("requesting_payment"), not null
#  refunded_at      :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  charge_id        :string(255)      not null
#  order_id         :bigint           not null
#
# Indexes
#
#  index_payments_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#
class Payment < ApplicationRecord
  belongs_to :order

  validates :charge_id, presence: true

  enum payment_progress: {
    requesting_payment: 0, # 決済手続き中
    failed_request: 1, # 手続き失敗
    canceled_request: 2, # 手続きキャンセル(存在しないかも)
    waiting_capture: 3, # 決済処理待ち
    captured: 4, # 購入済み
    failed_capture: 5, # 支払確定失敗
    requesting_refund: 6, # 返金手続き中
    waiting_refund: 7, # 返金処理待ち
    refunded: 8, # 返金済み
    failed_refund: 9 # 返金失敗
  }
end
