# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coupons', type: :request do
  describe 'GET /coupons', :sales_logged_in do
    subject(:coupons_index) { get sales_coupons_url(format: :json) }

    before do
      create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
    end

    let(:coupon) { create(:coupon, :available_coupon) }

    it 'HTTPステータスが200であること' do
      coupons_index
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::CouponSerializerの属性を持つハッシュであること' do
      coupons_index
      json = JSON.parse(response.body)
      json['coupons'].all? { |hash| expect(hash.keys).to match_array(::Sales::CouponSerializer._attributes.map { |key| key.to_s.camelize(:lower) }) }
    end

    it '所持しているクーポンを提供' do
      user2 = create(:user)
      create(:user_coupon, coupon: coupon, user: user2)
      coupons_index
      json = JSON.parse(response.body)
      expect(json['coupons'].size).to eq(sales_logged_in_user.coupons.size)
    end

    it '有効期限内のクーポンを提供' do
      unavailable_coupon = create(:coupon, available_end_at: Time.zone.now + 1.hour)
      create(:user_coupon, coupon: unavailable_coupon, user: sales_logged_in_user)
      coupons_index
      json = JSON.parse(response.body)
      expect(json['coupons'].size).to eq(1)
    end

    it '配布予定日時後のクーポンを提供' do
      available_end_at = Time.zone.now + 1.hour
      unavailable_coupon = create(:coupon, available_end_at: available_end_at, scheduled_distributed_at: available_end_at - rand(1..3).hour)
      create(:user_coupon, coupon: unavailable_coupon, user: sales_logged_in_user)
      coupons_index
      json = JSON.parse(response.body)
      expect(json['coupons'].size).to eq(1)
    end

    it '配布日時後のクーポンを提供' do
      available_end_at = Time.zone.now + 1.hour
      unavailable_coupon = create(:coupon, available_end_at: available_end_at, approved_at: available_end_at - 1.hour)
      create(:user_coupon, coupon: unavailable_coupon, user: sales_logged_in_user)
      coupons_index
      json = JSON.parse(response.body)
      expect(json['coupons'].size).to eq(1)
    end

    it 'キャンセルされていないクーポンを提供' do
      unavailable_coupon = create(:coupon)
      create(:user_coupon, coupon: unavailable_coupon, user: sales_logged_in_user)
      coupons_index
      json = JSON.parse(response.body)
      expect(json['coupons'].size).to eq(1)
    end

    it 'paginationが入っていること' do
      pagination =
        {
          'current' => 1,
          'previous' => nil,
          'next' => 2,
          'limitValue' => 6,
          'pages' => 2,
          'count' => 9,
          'pageCount' => 6
        }
      create_list(:coupon, 8, :available_coupon)
      Coupon.where.not(id: sales_logged_in_user.coupons.ids).each { |coupon| create(:user_coupon, coupon: coupon, user: sales_logged_in_user) }
      coupons_index
      json = JSON.parse(response.body)
      expect(json['pagination']).to eq(pagination)
    end

    context 'クーポン利用可能な開催が未販売の場合' do
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }

      before do
        create(:seat_sale, hold_daily_schedule: hold_daily_schedule)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
      end

      it 'クーポン情報は送られてこない' do
        coupons_index
        json = JSON.parse(response.body)
        expect(json['coupons'].size).to eq(0)
      end
    end
  end

  describe 'GET /available_coupons', :sales_logged_in do
    subject(:available_coupons) { get sales_available_coupons_url(params) }

    let(:coupon) { create(:coupon, :available_coupon) }

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
        it 'クーポン情報は送られてこない' do
          sales_logged_in_user
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(0)
        end
      end

      context '利用できるクーポンがある場合' do
        before do
          create(:user_coupon, user: sales_logged_in_user, coupon: coupon)
        end

        it 'クーポン情報が送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(1)
          expect(json[0]['id']).to eq(coupon.id)
          expect(json[0]['title']).to eq(coupon.title)
          expect(json[0]['rate']).to eq(coupon.rate)
          expect(json[0]['note']).to eq(coupon.note)
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
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
        end

        it 'クーポン情報が2つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(2)
          expect(json[1]['rate'] <= json[0]['rate']).to eq(true)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user)
          user2 = create(:user)
          create(:user_coupon, coupon: coupon, user: user2)
          create(:user_coupon, coupon: coupon2, user: user2)
        end

        it 'クーポン情報は送られてこない' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          user2 = create(:user)
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: user2)
        end

        it 'クーポン情報が1つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(1)
          expect(json[0]['id']).to eq(coupon.id)
          expect(json[0]['title']).to eq(coupon.title)
          expect(json[0]['rate']).to eq(coupon.rate)
          expect(json[0]['note']).to eq(coupon.note)
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

      context '持っているクーポン2つとも、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
          create(:seat_sale, :available, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule)
        end

        it 'クーポン情報が2つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(2)
          expect(json[1]['rate'] <= json[0]['rate']).to eq(true)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule2)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule2)
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }

        it 'クーポン情報の取得が出来ない' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
          create(:seat_sale, :available, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
          create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: hold_daily_schedule2)
        end

        let(:hold_daily_schedule2) { create(:hold_daily_schedule) }

        it 'クーポン情報が1つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(1)
          expect(json[0]['id']).to eq(coupon.id)
          expect(json[0]['title']).to eq(coupon.title)
          expect(json[0]['rate']).to eq(coupon.rate)
          expect(json[0]['note']).to eq(coupon.note)
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
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
          create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
          create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: master_seat_type)
        end

        let(:params) do
          {
            hold_daily_schedule_id: hold_daily_schedule.id,
            master_seat_type_ids: [master_seat_type.id, master_seat_type2.id]
          }
        end

        it 'クーポン情報が2つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(2)
          expect(json[1]['rate'] <= json[0]['rate']).to eq(true)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
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
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          user2 = create(:user)
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
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

        it 'クーポン情報が1つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(1)
          expect(json[0]['id']).to eq(coupon.id)
          expect(json[0]['title']).to eq(coupon.title)
          expect(json[0]['rate']).to eq(coupon.rate)
          expect(json[0]['note']).to eq(coupon.note)
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
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
          create(:seat_sale, :available, hold_daily_schedule: hold_daily_schedule)
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

        it 'クーポン情報が2つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(2)
          expect(json[1]['rate'] <= json[0]['rate']).to eq(true)
        end
      end

      context '持っているクーポン2つとも、使用出来ない場合' do
        before do
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
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
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(0)
        end
      end

      context '持っているのうちクーポン1つのみ、使用できる場合' do
        before do
          user2 = create(:user)
          create(:user_coupon, coupon: coupon, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon2, user: sales_logged_in_user)
          create(:user_coupon, coupon: coupon3, user: user2)
          create(:seat_sale, :available, hold_daily_schedule: hold_daily_schedule)
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

        it 'クーポン情報が1つ送られてくる' do
          available_coupons
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json.size).to eq(1)
          expect(json[0]['id']).to eq(coupon.id)
          expect(json[0]['title']).to eq(coupon.title)
          expect(json[0]['rate']).to eq(coupon.rate)
          expect(json[0]['note']).to eq(coupon.note)
        end
      end
    end
  end
end
