# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CartsController', type: :request do
  describe 'POST carts/', :sales_logged_in do
    subject(:request_ticket_order) { post sales_carts_url, params: params.to_json, headers: headers }

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type) { create(:template_seat_type, price: 1000) }
    let(:seat_type) { create(:seat_type, :available_for_sale, template_seat_type: template_seat_type) }
    let(:ticket) { create(:ticket, seat_type: seat_type) }
    let(:headers) { { 'Content-Type': 'application/json' } }

    let(:params) do
      { coupon_id: nil,
        order: [
          { ticketId: ticket_id, optionId: nil }
        ] }
    end

    context '成功' do
      let(:ticket_id) { ticket.id }

      it 'accepted_ticket_idsに指定チケットが含まれていること' do
        request_ticket_order
        expect(response).to have_http_status(:ok)
        cart = Cart.new(sales_logged_in_user)

        expect(cart.tickets).to eq([ticket])
      end
    end

    context '失敗' do
      context '存在しないチケットが含まれていた場合' do
        let(:ticket_id) { -1 }

        it 'not_found' do
          request_ticket_order
          error = I18n.t('custom_errors.orders.ticket_not_found')
          expect(JSON.parse(response.body)).to eq({ 'succeed' => false, 'error' => error, 'result' => {} })
        end
      end

      context 'オーダーが空の場合' do
        let(:params) do
          { coupon_id: nil,
            order: [] }
        end

        it 'cart_is_empty' do
          request_ticket_order
          error = I18n.t('custom_errors.orders.cart_is_empty')
          expect(JSON.parse(response.body)).to eq({ 'succeed' => false, 'error' => error, 'result' => {} })
        end
      end
    end
  end

  describe 'POST carts/ クーポン適用時', :sales_logged_in do
    subject(:request_ticket_order) { post sales_carts_url, params: params }

    before do
      create(:user_coupon, user: sales_logged_in_user, coupon: coupon)
      create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
      create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
    end

    let(:coupon) { create(:coupon, :available_coupon) }
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket_id) { ticket.id }
    let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }

    context '有効なクーポン情報を適用した時' do
      context 'オプションの指定が無い場合' do
        let(:params) do
          { coupon_id: coupon.id,
            order: [
              { ticketId: ticket_id, optionId: nil }
            ] }
        end

        it 'cartにクーポン情報が追加されること' do
          request_ticket_order
          expect(response).to have_http_status(:ok)
          res = JSON.parse(response.body)
          expect(res['result']['couponInfo']['couponTitle']).to eq(coupon.title)
        end
      end

      context 'オプションの指定が有る場合' do
        let(:params) do
          { coupon_id: coupon.id,
            order: [
              { ticketId: ticket_id, optionId: seat_type_option.id }
            ] }
        end

        it 'cartにチケット情報は入らない(オプションとクーポンの併用は出来ないため)' do
          request_ticket_order
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq({ 'succeed' => false, 'error' => 'このクーポンはオプションとの併用ができません', 'result' => {} })
        end
      end
    end

    context '無効なクーポン情報を適用した時' do
      context 'userが持っていないクーポンを利用した場合' do
        let(:user_coupon) { create(:user_coupon, user: other_user, coupon: coupon_1) }

        let(:other_user) { create(:user) }

        let(:coupon) { create(:coupon) }
        let(:coupon_1) { create(:coupon) }
        let(:params) do
          { coupon_id: coupon_1.id,
            order: [
              { ticketId: ticket_id, optionId: nil }
            ] }
        end

        it 'cartにチケット情報は入らない' do
          request_ticket_order
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq({ 'succeed' => false, 'error' => 'このクーポンはご利用できません', 'result' => {} })
        end
      end

      context '利用終了日時を過ぎていた場合' do
        let(:coupon) { create(:coupon, available_end_at: Time.zone.now - 1.hour) }
        let(:params) do
          { coupon_id: coupon.id,
            order: [
              { ticketId: ticket_id, optionId: nil }
            ] }
        end

        it 'cartにチケット情報は入らない' do
          request_ticket_order
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq({ 'succeed' => false, 'error' => 'このクーポンはご利用可能期限を過ぎています', 'result' => {} })
        end
      end

      context '対象の開催(hold_daily_schedule)で無い場合' do
        before do
          create(:seat_sale, :available)
        end

        let(:seat_sale_1) { create(:seat_sale, :available) }
        let(:seat_area) { create(:seat_area, seat_sale: seat_sale_1) }
        let(:seat_type) { create(:seat_type, seat_sale: seat_sale_1) }
        let(:ticket) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
        let(:params) do
          { coupon_id: coupon.id,
            order: [
              { ticketId: ticket_id, optionId: nil }
            ] }
        end

        it 'cartにチケット情報は入らない' do
          request_ticket_order
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq({ 'succeed' => false, 'error' => 'このクーポンはご指定の開催日程でのご利用ができません', 'result' => {} })
        end
      end
    end
  end

  describe 'GET carts/purchase_confirmation', :sales_logged_in do
    subject(:request_purchase_confirmation) { get sales_purchase_confirmation_url }

    context 'チケットがカートに入っている場合' do
      before do
        post sales_carts_url, params: params # cartにordersをいれる
      end

      let(:template_seat_type) { create(:template_seat_type, price: 1000) }
      let(:seat_type) { create(:seat_type, :available_for_sale, template_seat_type: template_seat_type) }
      let(:ticket) { create(:ticket, seat_type: seat_type) }
      let(:seat_sale_id) { seat_type.seat_sale.id }

      let(:params) do
        { coupon_id: nil,
          order: [
            { ticketId: ticket.id, optionId: nil }
          ] }
      end

      it 'レスポンスに指定チケットが含まれていること' do
        request_purchase_confirmation
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['ticketList'][0]['ticketId']).to eq(ticket.id)
      end
    end

    context 'チケットがカートに入っていない場合' do
      it '400エラーが返ってくること' do
        request_purchase_confirmation
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET carts/purchase_confirmation クーポン適用時', :sales_logged_in do
    subject(:request_purchase_confirmation) { get sales_purchase_confirmation_url }

    before do
      create(:user_coupon, user: sales_logged_in_user, coupon: coupon)
      create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
      create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
    end

    let(:coupon) { create(:coupon, :available_coupon) }
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:coupon2) { create(:coupon) }

    context 'チケットがカートに入っている場合' do
      before do
        post sales_carts_url, params: params # cartにordersをいれる
      end

      let(:params) do
        { coupon_id: coupon.id,
          order: [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil }
          ] }
      end

      it 'レスポンスに指定チケットとクーポンが含まれていること' do
        request_purchase_confirmation
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['ticketList'][0]['ticketId']).to eq(ticket1.id)
        expect(data['ticketList'][1]['ticketId']).to eq(ticket2.id)
        expect(data['couponInfo']['couponTitle']).to eq(coupon.title)
      end
    end

    context 'チケットがカートに入っていない場合' do
      it '400エラーが返ってくること' do
        request_purchase_confirmation
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET carts/seat_type_options_select', :sales_logged_in do
    subject(:seat_type_options_select) { get sales_carts_seat_type_options_select_url }

    context 'チケットがカートに入っている場合' do
      before do
        post sales_carts_url, params: params # cartにordersをいれる
        seat_type
        seat_type_option1
        seat_type_option2
      end

      let(:template_seat_type) { create(:template_seat_type, price: 1000) }
      let(:seat_type) { create(:seat_type, :available_for_sale, template_seat_type: template_seat_type) }
      let(:seat_type_option1) { create(:seat_type_option, seat_type: seat_type) }
      let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type) }
      let(:ticket) { create(:ticket, seat_type: seat_type) }
      let(:seat_sale_id) { seat_type.seat_sale.id }

      let(:params) do
        { coupon_id: nil,
          order: [
            { ticketId: ticket.id, optionId: nil }
          ] }
      end

      it 'レスポンスに指定チケットとオプション情報が含まれていること' do
        seat_type_options_select
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['ticketList'][0]['ticketId']).to eq(ticket.id)
        expect(data['ticketList'][0]['seatTypeOptionList'][0]['id']).to eq(seat_type_option1.id)
      end
    end

    context 'チケットがカートに入っていない場合、' do
      it '400エラーが返ってくること' do
        seat_type_options_select
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'GET carts/purchase_preview', :sales_logged_in do
    subject(:request_purchase_preview) { get sales_purchase_preview_url }

    before do
      create(:user_coupon, user: sales_logged_in_user, coupon: coupon)
      create(:user_coupon, user: sales_logged_in_user, coupon: coupon2)
      create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
      create(:coupon_hold_daily_condition, coupon: coupon2, hold_daily_schedule: seat_sale.hold_daily_schedule)
      create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
      create(:coupon_seat_type_condition, coupon: coupon2, master_seat_type: seat_type.master_seat_type)
    end

    let(:coupon) { create(:coupon, :available_coupon) }
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:coupon2) { create(:coupon) }

    context 'チケットがカートに入っている場合' do
      before do
        post sales_carts_url, params: params # cartにordersをいれる
      end

      let(:params) do
        { coupon_id: coupon.id,
          order: [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil }
          ] }
      end

      it 'accepted_ticket_idsに指定チケットが含まれていること' do
        request_purchase_preview
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['cart']['ticketList'][0]['ticketId']).to eq(ticket1.id)
        expect(data['cart']['ticketList'][1]['ticketId']).to eq(ticket2.id)
      end

      it '利用できるクーポンだけの確認' do
        request_purchase_preview
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['coupons'].size).to eq(1)
      end
    end

    context 'チケットがカートに入っていない場合' do
      it '400エラーが返ってくること' do
        request_purchase_preview
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
