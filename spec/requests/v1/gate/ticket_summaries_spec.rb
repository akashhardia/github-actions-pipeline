# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TicketSummaries', type: :request do
  include AuthenticationHelper

  describe 'GET /show' do
    subject(:show) { get v1_ticket_summaries_url(id: 1), params: params, headers: access_token }

    let(:params) { { data: 20_200_101 } }

    context '有効な競技場コードで且つ、指定された日付の開催がある場合' do
      before do
        # template_seat_type の価格は各1,000円
        order1 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
        order2 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2)
        create(:payment, order: order1)
        create(:payment, order: order2)
      end

      event_date = '20200101'
      let(:hold) { create(:hold, track_code: '01') }
      let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily2) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
      let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
      let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
      let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(5..9).hour, force_sales_stop_at: Time.zone.now - rand(0..4).hour) }

      it 'チケットを使って競技を見るために1競技場に入場したチケット購入者数とチケット売上金額のデータが取得できる' do
        show
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['ticket_customer']).to eq(2)
        expect(json['data']['ticket_amount']).to eq(2000)
      end
    end

    context '有効な競技場コードで且つ、指定された日付の開催がある場合で且つ、1回のオーダーで複数のチケットを購入している場合' do
      before do
        create(:payment, order: order)
        stub_const('TICKET_RESERVE_NUMBER', rand(1..5))
        # orderに紐づくtotal_priceは10,000
        create_list(:ticket_reserve, TICKET_RESERVE_NUMBER, order: order, ticket: ticket)
      end

      event_date = '20200101'
      let(:hold) { create(:hold, track_code: '01') }
      let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
      let(:seat_sale1) { create(:seat_sale, hold_daily_schedule: hold_daily_schedule1, sales_status: 'on_sale', sales_start_at: Time.zone.now - rand(0..4).hour) }
      let(:order) { create(:order, seat_sale: seat_sale1) }
      let(:ticket) { create(:ticket) }

      it 'チケットを使って競技を見るために1競技場に入場したチケット購入者数とチケット売上金額のデータが取得できる' do
        show
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['ticket_customer']).to eq(TICKET_RESERVE_NUMBER)
        expect(json['data']['ticket_amount']).to eq(10000)
      end
    end

    context 'DBに存在しない不正の競技場コードのパラメータが送られてきた場合' do
      before do
        order1 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
        order2 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2)

        create(:payment, order: order1)
        create(:payment, order: order2)
      end

      event_date = '20200101'
      let(:hold) { create(:hold, track_code: format('%02<number>d', number: rand(2..99))) }
      let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily2) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
      let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
      let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
      let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(5..9).hour, force_sales_stop_at: Time.zone.now - rand(0..4).hour) }

      it '404エラーを返す' do
        show
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include I18n.t('ticket.stadium_not_found')
      end
    end

    context '競技場コードは不正ではないが指定の日付に該当するレコードがない場合' do
      before do
        order1 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
        order2 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2)

        create(:payment, order: order1)
        create(:payment, order: order2)
      end

      event_date = '22220101'
      let(:hold) { create(:hold, track_code: '01') }
      let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily2) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
      let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
      let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1, sales_status: 'on_sale', sales_start_at: Time.zone.now - rand(0..4).hour) }
      let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2, sales_start_at: Time.zone.now - rand(5..9).hour, force_sales_stop_at: Time.zone.now - rand(0..4).hour) }

      it 'チケット購入者数とチケット売上金額のデータ共に0を返す' do
        show
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include I18n.t('ticket.data_for_this_date_not_found')
      end
    end

    context '販売実績の集計対象で無い開催の場合' do
      before do
        order1 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
        order2 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2)

        create(:payment, order: order1)
        create(:payment, order: order2)
      end

      event_date = '20200101'
      let(:hold) { create(:hold, track_code: '01') }
      let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily2) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
      let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
      let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1) }
      let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2) }

      it 'チケット購入者数とチケット売上金額のデータ共に0を返す' do
        show
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['ticket_customer']).to eq(0)
        expect(json['data']['ticket_amount']).to eq(0)
      end
    end

    context 'キャンセルされた注文(order)がある場合' do
      before do
        order1 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
        order2 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2, returned_at: Time.zone.now)

        create(:payment, order: order1)
        create(:payment, order: order2, payment_progress: :refunded)
      end

      event_date = '20200101'
      let(:hold) { create(:hold, track_code: '01') }
      let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily2) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date)) }
      let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
      let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
      let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
      let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(5..9).hour, force_sales_stop_at: Time.zone.now - rand(0..4).hour) }

      it 'キャンセルされたorderを除いた値を返す' do
        show
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['ticket_customer']).to eq(1)
        expect(json['data']['ticket_amount']).to eq(1000)
      end
    end

    context 'headerにaccess_tokenがない場合' do
      it '認証エラーとなる' do
        get v1_ticket_summaries_url(id: 1), params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
