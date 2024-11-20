# frozen_string_literal: true

# == Schema Information
#
# Table name: user_coupons
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  coupon_id  :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_coupons_on_coupon_id              (coupon_id)
#  index_user_coupons_on_coupon_id_and_user_id  (coupon_id,user_id) UNIQUE
#  index_user_coupons_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe UserCoupon, type: :model do
  describe '#coupon_id' do
    it 'coupon_idが必須チェックでエラーになること' do
      user_coupon = build(:user_coupon, coupon: nil)
      expect(user_coupon.invalid?).to be true
      expect(user_coupon.errors.messages[:coupon_id]).to include('を入力してください')
    end
  end

  describe '#user_id' do
    it 'user_idが必須チェックでエラーになること' do
      user_coupon = build(:user_coupon, user: nil)
      expect(user_coupon.invalid?).to be true
      expect(user_coupon.errors.messages[:user_id]).to include('を入力してください')
    end
  end

  describe 'coupon_idとuser_idのの同じ値同士の組み合わせが2つ以上になる場合' do
    let(:coupon) { create(:coupon) }
    let(:user) { create(:user) }

    it 'エラーになること' do
      create(:user_coupon, coupon: coupon, user: user)
      user_coupon = build(:user_coupon, coupon: coupon, user: user)
      user_coupon.valid?
      expect(user_coupon.errors.messages[:coupon_id]).to include('はすでに存在します')
    end
  end
end
