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
class OrderSerializer < ActiveModel::Serializer
  attributes :id, :order_type, :returned_at, :daily_no, :event_date, :promoter_year, :period, :round, :high_priority_event_code, :open_at, :start_at

  delegate :daily_no, :hold_name_jp, :event_date, :high_priority_event_code, to: :hold_daily_schedule
  delegate :promoter_year, :period, :round, to: :hold_daily

  def open_at
    hold_daily_schedule.opening_display
  end

  def start_at
    hold_daily_schedule.start_display
  end

  private

  def hold_daily_schedule
    object.seat_sale.hold_daily_schedule
  end

  def hold_daily
    object.seat_sale.hold_daily
  end
end
