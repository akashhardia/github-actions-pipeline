# frozen_string_literal: true

# == Schema Information
#
# Table name: coupon_seat_type_conditions
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  coupon_id           :bigint           not null
#  master_seat_type_id :bigint           not null
#
# Indexes
#
#  coupon_and_seat_type_index                                (coupon_id,master_seat_type_id) UNIQUE
#  index_coupon_seat_type_conditions_on_coupon_id            (coupon_id)
#  index_coupon_seat_type_conditions_on_master_seat_type_id  (master_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#
require 'rails_helper'

RSpec.describe CouponSeatTypeCondition, type: :model do
  describe '#coupon_id' do
    it 'coupon_idが必須チェックでエラーになること' do
      coupon_seat_type_condition = build(:coupon_seat_type_condition, coupon: nil)
      expect(coupon_seat_type_condition.invalid?).to be true
      expect(coupon_seat_type_condition.errors.messages[:coupon_id]).to include('を入力してください')
    end
  end

  describe '#master_seat_type_id' do
    it 'hold_daily_idが必須チェックでエラーになること' do
      coupon_seat_type_condition = build(:coupon_seat_type_condition, master_seat_type: nil)
      expect(coupon_seat_type_condition.invalid?).to be true
      expect(coupon_seat_type_condition.errors.messages[:master_seat_type]).to include('を入力してください')
    end
  end

  describe 'coupon_idとmaster_seat_type_idの同じ値同士の組み合わせが2つ以上になる場合' do
    let(:coupon) { create(:coupon) }
    let(:master_seat_type) { create(:master_seat_type) }

    it 'エラーになること' do
      create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
      coupon_seat_type_condition = build(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
      coupon_seat_type_condition.valid?
      expect(coupon_seat_type_condition.errors.messages[:coupon_id]).to include('はすでに存在します')
    end
  end
end
