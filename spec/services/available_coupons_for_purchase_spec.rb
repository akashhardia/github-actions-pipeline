# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AvailableCouponsForPurchase, type: :model do
  describe '#available_coupons' do
    subject(:available_coupons) do
      coupon_instance = described_class.new(params, total_user_coupons)
      coupon_instance.available_coupons
    end

    let(:coupon) { create(:coupon, :available_coupon) }
    let(:login_user) { create(:user) }
    let(:user2) { create(:user) }
    let(:total_user_coupons) do
      login_user.coupons.includes(:template_coupon).available(Time.zone.now) || []
    end

    context '制限が何も無い時' do
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }
      let(:master_seat_type) { create(:master_seat_type) }
      let(:master_seat_type_2) { create(:master_seat_type) }
      let(:params) do
        {
          hold_daily_schedule_id: hold_daily_schedule.id,
          master_seat_type_ids: [master_seat_type.id, master_seat_type_2.id]
        }
      end

      context '利用できるクーポンが無い場合' do
        it 'クーポン情報は取得出来ない' do
          expect(available_coupons.size).to eq(0)
        end
      end

      context '利用できるクーポンがある場合' do
        before do
          create(:user_coupon, user: login_user, coupon: coupon)
        end

        it 'クーポン情報が取得出来る' do
          expect(available_coupons.size).to eq(1)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
        end
      end
    end

    context '対象ユーザーのみに制限がある時' do
      let(:coupon2) { create(:coupon, :available_coupon) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }
      let(:master_seat_type) { create(:master_seat_type) }
      let(:master_seat_type_2) { create(:master_seat_type) }
      let(:params) do
        {
          hold_daily_schedule_id: hold_daily_schedule.id,
          master_seat_type_ids: [master_seat_type.id, master_seat_type_2.id]
        }
      end

      context '持っているクーポン2つとも、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
        end

        it 'クーポン情報が2つ取得出来る' do
          expect(available_coupons.size).to eq(2)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
          expect(available_coupons[1].id).to eq(coupon2.id)
          expect(available_coupons[1].title).to eq(coupon2.title)
          expect(available_coupons[1].rate).to eq(coupon2.rate)
          expect(available_coupons[1].note).to eq(coupon2.note)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user)
          create(:user_coupon, coupon: coupon, user: user2)
          create(:user_coupon, coupon: coupon2, user: user2)
        end

        it 'クーポン情報は取得出来ない' do
          expect(available_coupons.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: user2)
        end

        it 'クーポン情報が1つ取得出来る' do
          expect(available_coupons.size).to eq(1)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
        end
      end
    end

    context '開催日程のみに制限がある時' do
      let(:coupon2) { create(:coupon, :available_coupon) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }
      let(:master_seat_type) { create(:master_seat_type) }
      let(:master_seat_type_2) { create(:master_seat_type) }
      let(:params) do
        {
          hold_daily_schedule_id: hold_daily_schedule.id,
          master_seat_type_ids: [master_seat_type.id, master_seat_type_2.id]
        }
      end

      context '持っているクーポン2つとも、使用出来る場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule)
        end

        it 'クーポン情報が2つ取得出来る' do
          expect(available_coupons.size).to eq(2)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
          expect(available_coupons[1].id).to eq(coupon2.id)
          expect(available_coupons[1].title).to eq(coupon2.title)
          expect(available_coupons[1].rate).to eq(coupon2.rate)
          expect(available_coupons[1].note).to eq(coupon2.note)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule2)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule2)
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }

        it 'クーポン情報の取得が出来ない' do
          expect(available_coupons.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule2)
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }

        it 'クーポン情報が1つ取得出来る' do
          expect(available_coupons.size).to eq(1)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
        end
      end
    end

    context '席種のみに制限がある時' do
      let(:coupon2) { create(:coupon, :available_coupon) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }
      let(:master_seat_type) { create(:master_seat_type) }
      let(:master_seat_type2) { create(:master_seat_type) }

      context '持っているクーポン2つとも、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type)
        end

        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id, master_seat_type2.id]
          }
        end

        it 'クーポン情報が2つ取得出来る' do
          expect(available_coupons.size).to eq(2)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
          expect(available_coupons[1].id).to eq(coupon2.id)
          expect(available_coupons[1].title).to eq(coupon2.title)
          expect(available_coupons[1].rate).to eq(coupon2.rate)
          expect(available_coupons[1].note).to eq(coupon2.note)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type2)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type2)
        end

        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id]
          }
        end

        it 'クーポン情報の取得が出来ない' do
          expect(available_coupons.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:user_coupon, coupon: coupon3, user: user2)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type2)
          create(:coupon_seat_type_condition, coupon: coupon3, master_seat_type: master_seat_type3)
        end

        let(:master_seat_type3) { create(:master_seat_type) }
        let(:coupon3) { create(:coupon) }
        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id, master_seat_type3.id]
          }
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }

        it 'クーポン情報が1つ取得出来る' do
          expect(available_coupons.size).to eq(1)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
        end
      end
    end

    context '開催デイリ/席種共に制限がある時' do
      let(:coupon2) { create(:coupon, :available_coupon) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }
      let(:master_seat_type) { create(:master_seat_type) }
      let(:master_seat_type2) { create(:master_seat_type) }

      context '持っているクーポン2つとも、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type)
        end

        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id, master_seat_type2.id]
          }
        end

        it 'クーポン情報が2つ取得出来る' do
          expect(available_coupons.size).to eq(2)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
          expect(available_coupons[1].id).to eq(coupon2.id)
          expect(available_coupons[1].title).to eq(coupon2.title)
          expect(available_coupons[1].rate).to eq(coupon2.rate)
          expect(available_coupons[1].note).to eq(coupon2.note)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule2)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule2)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type2)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type2)
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }
        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id]
          }
        end

        it 'クーポン情報の取得が出来ない' do
          expect(available_coupons.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: login_user)
          create(:user_coupon, coupon: coupon2, user: login_user)
          create(:user_coupon, coupon: coupon3, user: user2)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule2)
          create(:coupon_hold_daily_condition, coupon: coupon3, hold_daily_schedule: hold_daily_schedule3)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type2)
          create(:coupon_seat_type_condition, coupon: coupon3, master_seat_type: master_seat_type3)
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }
        let(:hold_daily_schedule3) { create(:hold_daily_schedule) }
        let(:master_seat_type3) { create(:master_seat_type) }
        let(:coupon3) { create(:coupon) }
        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id, master_seat_type3.id]
          }
        end

        it 'クーポン情報が1つ取得出来る' do
          expect(available_coupons.size).to eq(1)
          expect(available_coupons[0].id).to eq(coupon.id)
          expect(available_coupons[0].title).to eq(coupon.title)
          expect(available_coupons[0].rate).to eq(coupon.rate)
          expect(available_coupons[0].note).to eq(coupon.note)
        end
      end
    end
  end
end
