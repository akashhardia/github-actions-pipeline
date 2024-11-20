# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id                   :bigint           not null, primary key
#  campaign_discount    :integer          default(0), not null
#  coupon_discount      :integer          default(0), not null
#  option_discount      :integer          default(0), not null
#  order_at             :datetime         not null
#  order_type           :integer          not null
#  refund_error_message :string(255)
#  returned_at          :datetime
#  total_price          :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  seat_sale_id         :bigint
#  user_coupon_id       :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  index_orders_on_seat_sale_id    (seat_sale_id)
#  index_orders_on_user_coupon_id  (user_coupon_id)
#  index_orders_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#  fk_rails_...  (user_coupon_id => user_coupons.id)
#  fk_rails_...  (user_id => users.id)
#
class Order < ApplicationRecord
  has_many :ticket_reserves, dependent: :destroy
  has_many :tickets, through: :ticket_reserves
  belongs_to :user
  belongs_to :seat_sale
  belongs_to :user_coupon, optional: true
  has_one :payment, dependent: :nullify
  has_one :campaign_usage, dependent: :destroy
  has_one :campaign, through: :campaign_usage

  delegate :coupon, to: :user_coupon, allow_nil: true

  # Validations -----------------------------------------------------------------------------------
  validates :order_at, presence: true
  validates :order_type, presence: true
  validates :total_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true
  validates :seat_sale_id, presence: true
  validates :user_id, presence: true

  enum order_type: {
    purchase: 0, # 新規購入
    transfer: 1, # 譲渡
    admin_transfer: 2 # 管理画面譲渡
  }

  scope :accounting_target, -> { left_outer_joins(:payment).where(order_type: :purchase, returned_at: nil, payment: { payment_progress: :captured }) }
  scope :payment_captured_or_refunded, -> { left_outer_joins(:payment).where(order_type: :purchase, payment: { payment_progress: [:captured, :refunded] }) }

  # 決済済みorder
  scope :captured, -> do
    includes(:payment).where(payment: { payment_progress: :captured })
  end
end
