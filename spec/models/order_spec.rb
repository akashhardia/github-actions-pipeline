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
require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:user) { create(:user) }
  let(:seat_sale) { create(:seat_sale) }

  describe 'validationの確認' do
    it 'order_atがなければerrorになること' do
      order = described_class.new(order_type: :purchase, total_price: 10_000, seat_sale: seat_sale, user: user)
      expect(order.valid?).to eq false
    end

    it 'order_typeがなければerrorになること' do
      order = described_class.new(order_at: Time.zone.today, total_price: 10_000, seat_sale: seat_sale, user: user)
      expect(order.valid?).to eq false
    end

    it 'total_priceがなければerrorになること' do
      order = described_class.new(order_at: Time.zone.today, order_type: :purchase, seat_sale: seat_sale, user: user)
      expect(order.valid?).to eq false
    end

    it 'seat_saleがなければerrorになること' do
      order = described_class.new(order_at: Time.zone.today, order_type: :purchase, total_price: 10_000, user: user)
      expect(order.valid?).to eq false
    end

    it 'userがなければerrorになること' do
      order = described_class.new(order_at: Time.zone.today, order_type: :purchase, total_price: 10_000, seat_sale: seat_sale)
      expect(order.valid?).to eq false
    end
  end
end
