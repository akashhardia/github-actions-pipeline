# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CouponCreator, type: :model do
  let(:coupon) { create(:coupon) }
  let(:template_coupon) { create(:template_coupon) }
  let(:seat_sale) { create(:seat_sale, :available) }
  let(:master_seat_type) { create(:master_seat_type) }

  before do
    create(:user, sixgram_id: 1)
    create(:user, sixgram_id: 2)
    create(:user, sixgram_id: 3)
    create(:user, sixgram_id: 4)
    create(:user, sixgram_id: 5)
  end

  describe '#create_coupon!' do
    subject(:create_coupon!) do
      coupon_instance = described_class.new(params)
      coupon_instance.create_coupon!
    end

    context '正常に必須項目が送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: coupon.available_end_at.to_s }.to_json,
          holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id].to_json,
          masterSeatTypeIds: [master_seat_type.id].to_json }.with_indifferent_access
      end

      it 'template_couponとcouponが作成される' do
        template_coupon
        coupon
        expect { create_coupon! }.to change(TemplateCoupon, :count).by(1).and change(Coupon, :count).by(1)
      end
    end

    context '存在しないhold_daily_schedule_idが送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: coupon.available_end_at.to_s }.to_json,
          holdDailyScheduleIds: [9999].to_json,
          masterSeatTypeIds: [master_seat_type.id].to_json }.with_indifferent_access
      end

      it 'エラーが上がる' do
        expect { create_coupon! }.to raise_error(CustomError)
      end
    end

    context '存在しないmaster_seat_type_idが送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: coupon.available_end_at.to_s }.to_json,
          holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id].to_json,
          masterSeatTypeIds: [9999].to_json }.with_indifferent_access
      end

      it 'エラーが上がる' do
        expect { create_coupon! }.to raise_error(CustomError)
      end
    end
  end
end
