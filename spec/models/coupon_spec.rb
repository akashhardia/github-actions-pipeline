# frozen_string_literal: true

# == Schema Information
#
# Table name: coupons
#
#  id                       :bigint           not null, primary key
#  approved_at              :datetime
#  available_end_at         :datetime         not null
#  canceled_at              :datetime
#  scheduled_distributed_at :datetime
#  user_restricted          :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  template_coupon_id       :bigint           not null
#
# Indexes
#
#  index_coupons_on_template_coupon_id  (template_coupon_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_coupon_id => template_coupons.id)
#
require 'rails_helper'

RSpec.describe Coupon, type: :model do
  # 念の為、FactoryBotで生成されるランダムの値に対しての検証を行う。
  describe 'FactoryBot' do
    let(:coupon) { create(:coupon) }

    it 'FactoryBotの値が正常にチェックされるかどうか' do
      coupon
      expect(coupon).to be_valid
    end
  end

  describe '#available_end_at' do
    it 'available_end_atが必須チェックでエラーになること' do
      coupon = build(:coupon, :available_end_at_nil)
      expect(coupon.invalid?).to be true
      expect(coupon.errors.messages[:available_end_at]).to include('を入力してください')
    end
  end

  describe '#各開始日時が利用終了日時を超えた場合のエラーチェック' do
    it 'scheduled_distributed_atがavailable_end_atを超えた場合はエラーになること' do
      coupon = build(:coupon, scheduled_distributed_at: Time.zone.now + rand(5..9).hour, available_end_at: Time.zone.now)
      expect(coupon.invalid?).to be true
    end

    it 'approved_atがavailable_end_atを超えた場合はエラーになること' do
      coupon = build(:coupon, approved_at: Time.zone.now + rand(5..9).hour, available_end_at: Time.zone.now)
      expect(coupon.invalid?).to be true
    end
  end

  describe 'scope:available' do
    before do
      create(:coupon, :available_coupon)
    end

    let(:available_end_at) { Time.zone.now + rand(5..9).hour }

    it '有効期限内のクーポンを提供' do
      create(:coupon, available_end_at: Time.zone.now - rand(5..9).hour)
      available_coupons = described_class.available(Time.zone.now)
      expect(available_coupons.size).to eq(1)
    end

    it '配布予定日時後のクーポンを提供' do
      create(:coupon, available_end_at: available_end_at, scheduled_distributed_at: available_end_at - rand(1..3).hour)
      available_coupons = described_class.available(Time.zone.now)
      expect(available_coupons.size).to eq(1)
    end

    it '配布日時後のクーポンを提供' do
      create(:coupon, available_end_at: available_end_at, approved_at: available_end_at - rand(1..3).hour)
      available_coupons = described_class.available(Time.zone.now)
      expect(available_coupons.size).to eq(1)
    end

    it 'キャンセルされていないクーポンを提供' do
      create(:coupon)
      available_coupons = described_class.available(Time.zone.now)
      expect(available_coupons.size).to eq(1)
    end
  end

  describe 'scope:available_to_user(user)' do
    let(:user) { create(:user) }
    let(:available_end_at) { Time.zone.now + rand(5..9).hour }
    let(:cart_coupon) { nil }

    before do
      coupon = create(:coupon, :available_coupon)
      create(:user_coupon, coupon: coupon, user: user)
    end

    it 'ユーザーが使用可能なクーポンを提供' do
      coupon = create(:coupon, :available_coupon)
      user_coupon = create(:user_coupon, coupon: coupon, user: user)
      order = create(:order, user: user, user_coupon: user_coupon)
      create(:payment, order: order)

      available_coupons = described_class.available_to_user(user, Time.zone.now, cart_coupon)
      expect(available_coupons.size).to eq(1)
    end
  end

  describe '#be_available_hold_daily' do
    let(:coupon) { create(:coupon, :available_coupon) }

    context '利用可能な開催に制限がない場合' do
      it { expect(coupon.be_available_hold_daily).to be_truthy }
    end

    context '利用可能な開催に制限があり、販売中の開催を含んでいない場合' do
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }

      before do
        create(:seat_sale, hold_daily_schedule: hold_daily_schedule)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
      end

      it { expect(coupon.be_available_hold_daily).to be_falsey }
    end

    context '利用可能な開催に制限があり、販売中の開催を含んでいる場合' do
      let(:on_sale_hold_daily_schedule) { create(:hold_daily_schedule) }
      let(:before_sale_hold_daily_schedule) { create(:hold_daily_schedule) }

      before do
        create(:seat_sale, :available, hold_daily_schedule: on_sale_hold_daily_schedule)
        create(:seat_sale, hold_daily_schedule: before_sale_hold_daily_schedule)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: on_sale_hold_daily_schedule)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: before_sale_hold_daily_schedule)
      end

      it { expect(coupon.be_available_hold_daily).to be_truthy }
    end
  end

  describe 'be_unused_user_coupon(user)' do
    let(:user) { create(:user) }
    let(:cart_coupon) { nil }

    context 'ユーザーが未使用なクーポンの場合' do
      it 'trueを返す' do
        coupon = create(:coupon, :available_coupon)
        create(:user_coupon, coupon: coupon, user: user)

        expect(coupon.be_unused_user_coupon(user, cart_coupon)).to be_truthy
      end
    end

    context 'ユーザーが使用したクーポンの場合' do
      it 'falseを返す' do
        coupon = create(:coupon, :available_coupon)
        user_coupon = create(:user_coupon, coupon: coupon, user: user)
        order = create(:order, user: user, user_coupon: user_coupon)
        create(:payment, order: order)
        expect(coupon.be_unused_user_coupon(user, cart_coupon)).to be_falsey
      end
    end

    context 'ユーザーに配布されていないクーポンの場合' do
      it 'falseを返す' do
        coupon = create(:coupon, :available_coupon)

        expect(coupon.be_unused_user_coupon(user, cart_coupon)).to be_falsey
      end
    end

    context 'カートに入ってて決済が完了してないクーポンの場合(ブラウザバック)' do
      it 'trueを返す' do
        coupon = create(:coupon, :available_coupon)
        user_coupon = create(:user_coupon, coupon: coupon, user: user)
        order = create(:order, user: user, user_coupon: user_coupon)
        create(:payment, order: order, payment_progress: :requesting_payment)
        cart_coupon = order

        expect(coupon.be_unused_user_coupon(user, cart_coupon)).to be_truthy
      end
    end
  end
end
