# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Orders', :admin_logged_in, type: :request do
  describe 'GET admin/orders/:id' do
    subject(:order_show) do
      create(:payment, order: order)
      get admin_orders_show_url(order.id, format: :json)
    end

    let(:user) { create(:user) }
    let(:coupon) { create(:coupon) }
    let(:user_coupon) { user.user_coupons.create(coupon: coupon) }
    let(:order) { create(:order, :with_ticket_and_build_reserves, user: user, order_at: Time.zone.now, user_coupon_id: user_coupon.id) }

    it 'HTTPステータスが200であること' do
      order_show
      expect(response).to have_http_status(:ok)
    end

    it 'jsonはAdmin::OrderSerializerの属性を持つハッシュであること' do
      order_show
      json = JSON.parse(response.body)
      expect(json['id']).to eq(order.id)
      expect(json['totalPrice']).to eq(order.total_price)
      expect(json['createdAt']).to be_present
      expect(json['paymentStatus']).to eq(order.payment.payment_progress)
      expect(json['returnedAt']).to eq(order.returned_at&.to_s)
      expect(json['usedCoupon']).to eq("#{order.coupon.title}(ID: #{order.coupon.id})")
    end

    it 'orderが見つからない場合はnot_foundが返ること' do
      get admin_orders_show_url(99999, format: :json)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET admin/orders/:id/ticket_reserves' do
    subject(:ticket_reserves) do
      get admin_ticket_reserves_order_url(order.id)
    end

    let(:user) { create(:user) }
    let(:seat_sale) { create(:seat_sale, :in_term) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user) }
    let(:order) { create(:order, user: user, seat_sale: seat_sale) }

    before do
      create(:ticket_reserve, order: order, ticket: ticket)
    end

    context '対象のorderに属するチケット' do
      it 'HTTPステータスが200であること' do
        ticket_reserves
        expect(response).to have_http_status(:ok)
      end

      it '想定しているjsonレスポンスが返ってくること' do
        ticket_reserves
        json = JSON.parse(response.body)[0]
        ticket_reserve = TicketReserve.first
        expect(json['id']).to eq(ticket_reserve.id)
        expect(json['qrTicketId']).to eq(nil)
        expect(json['transferStatus']).to eq('notDone')
        expect(json['eventDate']).to eq(ticket_reserve.order.seat_sale.hold_daily_schedule.event_date.to_s)
        expect(json['dailyNo']).to eq('am')
        expect(json['holdNameJp']).to eq('MyString')
        expect(json['admissionTime']).to eq(ticket.seat_sale.admission_available_at.strftime('%H:%M'))
        expect(json['ticketStatus']).to eq('before_enter')
        expect(json['updatedAt']).to be_present
        expect(json['ticketId']).to eq(ticket.id)
      end

      it 'チケットログがresult=falseは無視してステータスが返ってくること' do
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :entered)
        create(:ticket_log, ticket: ticket, result: 'false', result_status: :left)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['ticketStatus']).to eq('entered')
      end
    end
  end

  describe 'PUT admin/orders/:id/ticket_refund' do
    subject(:ticket_refund) do
      put admin_ticket_refund_order_url(order.id, format: :json)
    end

    let(:user) { create(:user) }
    let(:order) { create(:order, :with_ticket_and_build_reserves_sold, user: user, order_at: Time.zone.now, payment: payment) }
    let(:payment) { create(:payment, charge_id: charge_id, payment_progress: :captured) }
    let(:charge_id) { 'charge_id' }

    context '返金処理正常ケース' do
      it 'HTTPステータスが200であること' do
        ticket_refund
        expect(response).to have_http_status(:ok)
        expect(payment.reload.payment_progress).to eq('refunded')
        expect(order.reload.returned_at).not_to eq(nil)
        expect(user.tickets).to eq([])
        expect(user.tickets.all?(&:not_for_sale?)).to be true
        expect(payment.reload.refunded_at).not_to eq(nil)
      end
    end

    context '返金処理エラーケース' do
      context 'すでに返金処理済みの場合' do
        it 'エラーが帰ること' do
          order.update(returned_at: Time.zone.now)
          ticket_refund
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('返金処理済みです。')
        end
      end
    end
  end

  describe 'GET admin/orders/export_csv' do
    subject(:order_export_csv) do
      get admin_orders_export_csv_url(format: :json), params: { seat_sale_ids: seat_sale_ids }
    end

    let(:seat_sale_ids) { [order_1.seat_sale_id, order_2.seat_sale_id, order_3.seat_sale_id, order_4.seat_sale_id, order_5.seat_sale_id,] }
    let(:order_1) { create(:order, :payment_captured, campaign_discount: 1000) }
    let(:order_2) { create(:order, :payment_captured, order_type: :transfer) }
    let(:order_3) { create(:order, :payment_captured, order_type: :admin_transfer) }
    let(:order_4) { create(:order, :payment_refunded, returned_at: Time.zone.now) }
    let(:order_5) { create(:order, :payment_waiting_capture) }
    let(:campaign) { create(:campaign) }
    let(:campaign_usage) { create(:campaign_usage, campaign: campaign, order: order_1) }

    before do
      order_1
      order_2
      order_3
      order_4
      order_5
      campaign
      campaign_usage
    end

    it 'HTTPステータスが200であること' do
      order_export_csv
      expect(response).to have_http_status(:ok)
    end

    it 'jsonはAdmin::CsvExportOrderSerializerの属性を持つハッシュであること' do
      order_export_csv
      json = JSON.parse(response.body)
      attributes = ::Admin::CsvExportOrderSerializer._attributes
      json.all? { |hash| expect(hash.keys).to match_array(attributes.map { |key| key.to_s.camelize(:lower) }) }
    end

    it 'order_typeがpurchaseでpaymentがcaptured,refundedのもののみ返ること' do
      order_export_csv
      json = JSON.parse(response.body)
      expect(json.count).to be(2)
      expect(json.map { |hash| hash['id'] }).to match_array([order_1.id, order_4.id])
    end

    it 'created_atとreturned_atのフォーマットが%Y-%m-%d %H:%M:%Sであること' do
      order_export_csv
      json = JSON.parse(response.body)
      expect(json[1]['createdAt']).to eq(order_4.created_at.strftime('%Y-%m-%d %H:%M:%S'))
      expect(json[1]['returnedAt']).to eq(order_4.returned_at.strftime('%Y-%m-%d %H:%M:%S'))
    end

    it 'キャンペーンが使われたオーダーはキャンペーンidとキャンペーンtitleが返ること' do
      order_export_csv
      json = JSON.parse(response.body)
      expect(json[0]['campaignId']).to eq(order_1.campaign.id)
      expect(json[0]['campaignTitle']).to eq(order_1.campaign.title)
      expect(json[0]['campaignDiscount']).to eq(order_1.campaign_discount)
      expect(json[1]['campaignId']).to be nil
      expect(json[1]['campaignTitle']).to be nil
      expect(json[1]['campaignDiscount']).to be 0
    end
  end

  describe 'GET admin/orders/:id/charge_status' do
    subject(:charge_status) { get admin_charge_status_order_url(order.id) }

    let(:order) { create(:order) }

    context 'charge_statusが存在する場合' do
      before do
        create(:payment, order: order)
      end

      it 'HTTPステータスが200であること' do
        charge_status
        expect(response).to have_http_status(:ok)
      end

      it '想定しているjsonレスポンスが返ってくること' do
        charge_status
        json = JSON.parse(response.body)
        response_params = ApiProvider.sixgram_payment.charge_status(order.payment.charge_id).to_s
        expect_data = %w[requestParams responseHttpStatus responseParams]
        expect(json['responseParams']).to eq(response_params)
        expect(expect_data).to include_keys(json.keys)
        expect(json['requestParams']['chargeId']).to eq(order.payment.charge_id)
        expect(json['responseHttpStatus']).to eq(200)
      end
    end

    context 'charge_statusが存在しない場合' do
      it 'HTTPステータスが400であること' do
        create(:payment, order: order, charge_id: '211115')
        charge_status
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
