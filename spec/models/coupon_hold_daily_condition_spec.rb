# frozen_string_literal: true

# == Schema Information
#
# Table name: coupon_hold_daily_conditions
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  coupon_id              :bigint           not null
#  hold_daily_schedule_id :bigint           not null
#
# Indexes
#
#  coupon_and_hold_daily_index                                   (coupon_id,hold_daily_schedule_id) UNIQUE
#  index_coupon_hold_daily_conditions_on_coupon_id               (coupon_id)
#  index_coupon_hold_daily_conditions_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#
require 'rails_helper'

RSpec.describe CouponHoldDailyCondition, type: :model do
  describe '#coupon_id' do
    it 'coupon_idが必須チェックでエラーになること' do
      coupon_hold_daily_condition = build(:coupon_hold_daily_condition, coupon: nil)
      expect(coupon_hold_daily_condition.invalid?).to be true
      expect(coupon_hold_daily_condition.errors.messages[:coupon_id]).to include('を入力してください')
    end
  end

  describe '#hold_daily_id' do
    it 'hold_daily_idが必須チェックでエラーになること' do
      coupon_hold_daily_condition = build(:coupon_hold_daily_condition, hold_daily_schedule: nil)
      expect(coupon_hold_daily_condition.invalid?).to be true
      expect(coupon_hold_daily_condition.errors.messages[:hold_daily_schedule_id]).to include('を入力してください')
    end
  end

  describe 'coupon_idとhold_daily_schedule_idのの同じ値同士の組み合わせが2つ以上になる場合' do
    let(:coupon) { create(:coupon) }
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }

    it 'エラーになること' do
      create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
      coupon_hold_daily_condition = build(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
      coupon_hold_daily_condition.valid?
      expect(coupon_hold_daily_condition.errors.messages[:coupon_id]).to include('はすでに存在します')
    end
  end
end
