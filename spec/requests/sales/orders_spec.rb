# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  describe 'GET /orders', :sales_logged_in do
    subject(:order_index) do
      order = create(:order, :with_ticket_and_build_reserves, user: sales_logged_in_user, order_at: Time.zone.now)
      create(:payment, order: order, payment_progress: payment_progress)
      get sales_orders_url(format: :json)
    end

    context '支払い状況が購入済みの場合' do
      let(:payment_progress) { :captured }

      it 'HTTPステータスが200であること' do
        order_index
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['orders'].length).to eq sales_logged_in_user.orders.length
      end

      it 'json[:orders]は::OrderSerializerの属性を持つハッシュであること' do
        order_index
        json = JSON.parse(response.body)
        json['orders'].all? { |hash| expect(hash.keys).to match_array(::OrderSerializer._attributes.map { |key| key.to_s.camelize(:lower) }) }
      end

      it '申込の開催デイリの情報の確認' do
        order_index
        json = JSON.parse(response.body)['orders']
        hold_daily_schedule = sales_logged_in_user.tickets.first.seat_type.seat_sale.hold_daily_schedule
        expect(json.first['dailyNo']).to eq(hold_daily_schedule.daily_no)
        expect(json.first['promoterYear']).to eq(hold_daily_schedule.hold_daily.promoter_year)
      end

      it 'orderのorder_typeがpurchaseの分のみが返されること' do
        9.times do |_n|
          order = create(:order, :with_ticket_and_build_reserves, user: sales_logged_in_user, order_at: Time.zone.now, order_type: [0, 1].sample)
          create(:payment, order: order)
        end
        order_index
        count = Order.purchase.count
        json = JSON.parse(response.body)
        expect(json['orders'].count).to eq(count)
      end

      it 'ページネーションの確認' do
        pagination =
          {
            'current' => 1,
            'previous' => nil,
            'next' => 2,
            'pageCount' => 10,
            'limitValue' => 10,
            'pages' => 3,
            'count' => 21
          }
        20.times do |_n|
          order = create(:order, :with_ticket_and_build_reserves, user: sales_logged_in_user, order_at: Time.zone.now)
          create(:payment, order: order)
        end

        order_index
        json = JSON.parse(response.body)['pagination']
        expect(json).to eq(pagination)
      end

      it 'orderのidの降順であること' do
        10.times do |_n|
          order = create(:order, :with_ticket_and_build_reserves, user: sales_logged_in_user, order_at: Time.zone.now, order_type: 0)
          create(:payment, order: order)
        end
        order_index
        orders = Order.order(id: 'DESC')
        json = JSON.parse(response.body)
        expect(json['orders'][0]['id']).to eq(orders.first.id)
        expect(json['orders'][1]['id']).to eq(orders.second.id)
        expect(json['orders'][2]['id']).to eq(orders.third.id)
      end
    end

    context '支払い（payment）が返金済み（:refunded）の場合' do
      let(:payment_progress) { :refunded }

      it '出力されること' do
        order_index
        count = Order.purchase.count
        json = JSON.parse(response.body)
        expect(json['orders'].count).to eq(count)
      end
    end

    context '支払い（payment）が購入済みまたは返金済み以外の場合' do
      let(:payment_progress) { :requesting_payment }

      it '出力されないこと' do
        order_index
        json = JSON.parse(response.body)
        expect(json['orders'].count).to eq(0)
      end
    end
  end

  describe 'GET /orders/:id', :sales_logged_in do
    subject(:order_show) { get sales_order_url(order, format: :json) }

    let(:order) { create(:order, :with_ticket_and_build_reserves, user: sales_logged_in_user, order_at: Time.zone.now) }

    it 'HTTPステータスが200であること' do
      order_show
      expect(response).to have_http_status(:ok)
    end

    it 'json[:orders]は::OrderDetailSerializerの属性を持つハッシュであること' do
      order_show
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(::OrderDetailSerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end

    it '申込の開催デイリの情報の確認' do
      order_show
      json = JSON.parse(response.body)['holdDailySchedule']
      hold_daily_schedule = sales_logged_in_user.tickets.first.seat_type.seat_sale.hold_daily_schedule
      expect(json['dailyNo']).to eq(hold_daily_schedule.daily_no)
      expect(json['eventDate']).to eq(hold_daily_schedule.event_date.to_s)
      expect(json['dayOfWeek']).to eq(hold_daily_schedule.event_date.wday)
      expect(json['promoterYear']).to eq(hold_daily_schedule.hold_daily.promoter_year)
    end

    context 'クーポンを利用した場合' do
      let(:coupon) { create(:coupon) }
      let(:user_coupon) { create(:user_coupon, coupon: coupon) }
      let(:order) { create(:order, :with_ticket_and_build_reserves, user: sales_logged_in_user, order_at: Time.zone.now, user_coupon: user_coupon) }

      it 'クーポンの情報の確認' do
        order_show
        json = JSON.parse(response.body)
        expect(json['coupon']['title']).to eq(coupon.title)
        expect(json['coupon']['rate']).to eq(coupon.rate)
      end
    end

    context 'キャンペーンを利用した場合' do
      let(:campaign) { create(:campaign) }

      it 'キャンペーンの情報の確認' do
        create(:campaign_usage, campaign: campaign, order: order)
        order_show
        json = JSON.parse(response.body)
        expect(json['campaign']['title']).to eq(campaign.title)
        expect(json['campaign']['discountRate']).to eq(campaign.discount_rate)
      end
    end
  end

  describe 'GET /orders/pre_request', :sales_logged_in do
    subject(:pre_request) { get sales_orders_pre_request_url }

    before do
      cart.replace_tickets(orders, nil, nil)
    end

    let(:cart) { Cart.new(sales_logged_in_user) }
    let(:orders) do
      [
        { ticket_id: ticket.id, option_id: nil },
      ]
    end

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

    context '決済手続きリクエストが成功する場合' do
      it '決済手続きページへリダイレクトされること' do
        pre_request
        charge_id = sales_logged_in_user.orders.first.payment.charge_id
        expect(response).to redirect_to("#{Sixgram::MockUser::MOCK_PAYMENT_PATH}?charge_id=#{charge_id}")
        expect(cart.charge_id.present?).to be true
      end
    end

    context '販売期間外になった場合' do
      before do
        seat_sale.update!(sales_start_at: Time.zone.now - 2.hours, sales_end_at: Time.zone.now - 1.hour)
      end

      it '選択内容確認ページにリダイレクトされること' do
        pre_request
        expect(response).to redirect_to("#{Rails.application.credentials.environmental[:sales_front_host_name]}/purchase/preview?error=sale_term_outside")
      end
    end
    # TODO: NGユーザーチェックスキップ
    # context 'NGユーザーだった場合' do
    #   let(:sales_logged_in_user_sixgram_id) { '09000010002' }

    #   it 'エラーページにリダイレクトされる前にログインできない' do
    #     pre_request
    #     expect(response).to have_http_status(:unauthorized)
    #     body = JSON.parse(response.body)
    #     expect(body['code']).to eq('login_required')
    #     expect(session[:user_auth_token].present?).to be false
    #   end
    # end
  end

  describe 'GET /orders/capture2', :sales_logged_in do
    subject(:capture2) { get sales_orders_capture2_url }

    before do
      cart.replace_tickets(orders, nil, nil)
      create(:ticket_reserve, order: order, ticket: ticket, seat_type_option: nil)
      cart.replace_cart_charge_id(payment.charge_id)
    end

    let(:cart) { Cart.new(sales_logged_in_user) }
    let(:orders) do
      [
        { ticket_id: ticket.id, option_id: nil },
      ]
    end

    let(:orders2) do
      [
        { ticket_id: ticket2.id, option_id: nil },
      ]
    end

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

    let(:order) { create(:order, total_price: total_price) }
    let(:order2) { create(:order, total_price: total_price) }
    let(:payment) { create(:payment, order: order, charge_id: charge_id, payment_progress: :requesting_payment) }
    let(:payment2) { create(:payment, order: order2, charge_id: charge_id2, payment_progress: :requesting_payment) }
    let(:total_price) { 6000 }
    let(:charge_id) { 'charge_id' }
    let(:charge_id2) { 'charge_id' }

    context '支払確定が成功する場合' do
      it '正常終了し、charge_idを渡していること' do
        capture2
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['error']).to eq(nil)
        expect(json['chargeId']).to eq(charge_id)
      end

      it '同じcharge_idで決済をしようとすると、先の決済は正常終了し後からの決済はエラーを返すこと' do
        capture2
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['error']).to eq(nil)
        expect(json['chargeId']).to eq(charge_id)

        cart.replace_tickets(orders2, nil, nil)
        create(:ticket_reserve, order: order2, ticket: ticket2, seat_type_option: nil)
        cart.replace_cart_charge_id(payment2.charge_id)

        get sales_orders_capture2_url
        json = JSON.parse(response.body)
        expect(json['code']).to eq('internal_server_error')
        expect(json['status']).to eq(500)
      end

      context '違うcharge_idで決済をしようとする' do
        let(:charge_id2) { 'charge_id_second' }

        it 'どちらも正常終了すること' do
          capture2
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json['error']).to eq(nil)
          expect(json['chargeId']).to eq(charge_id)

          cart.replace_tickets(orders2, nil, nil)
          create(:ticket_reserve, order: order2, ticket: ticket2, seat_type_option: nil)
          cart.replace_cart_charge_id(payment2.charge_id)

          get sales_orders_capture2_url
          json = JSON.parse(response.body)
          expect(json['error']).to eq(nil)
          expect(json['chargeId']).to eq(charge_id2)
        end
      end
    end

    context '与信エラー（6gramのレスポンスエラー）の場合' do
      let(:charge_id) { '211114' }

      it '正常終了で、errorを返す' do
        capture2
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['error']).to eq('failed_request')
        expect(json['chargeId']).to eq(nil)
      end
    end

    context '支払確定時エラー（6gramのレスポンスエラー）の場合' do
      let(:charge_id) { '412112' }

      it '正常終了で、errorを返す' do
        capture2
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['error']).to eq('already_refunded')
        expect(json['chargeId']).to eq(nil)
      end
    end

    context 'already_capture_errorの場合' do
      let(:charge_id) { '412111' }

      it '正常終了すること' do
        capture2
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['error']).to eq(nil)
        expect(json['chargeId']).to eq(charge_id)
      end
    end

    context 'カートの期限切れになった場合' do
      before do
        cart.clear_hold_tickets
      end

      it '予期せぬエラーが発生すること' do
        capture2
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'internal_server_error', 'detail' => '予期せぬエラーが発生しました', 'status' => 500 })
      end
    end

    context '販売期間外になった場合' do
      before do
        seat_sale.update!(sales_start_at: Time.zone.now - 2.hours, sales_end_at: Time.zone.now - 1.hour)
      end

      it '予期せぬエラーが発生すること' do
        capture2
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'fatal_sixgram_payment_error', 'detail' => '予期せぬエラーが発生しました', 'status' => 500 })
      end
    end
  end

  describe 'GET orders/purchase_complete', :sales_logged_in do
    subject(:request_purchase_complete) { get sales_purchase_complete_url params: { charge_id: payment.charge_id } }

    before do
      create(:race, event_code: 'T', hold_daily_schedule: hold_daily_schedule)
      tr = create(:ticket_reserve, order: order, ticket: ticket, seat_type_option: seat_type_option)
      ticket.update(current_ticket_reserve_id: tr.id)
    end

    let(:hold) { create(:hold, promoter_year: '2020', period: 3, round: 5) }
    let(:hold_daily) { create(:hold_daily, hold: hold) }
    let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily) }

    let(:seat_sale) { create(:seat_sale, :available, hold_daily_schedule: hold_daily_schedule) }

    let(:template_seat_type) { create(:template_seat_type, price: 5000) }
    let(:template_seat_type_option) { create(:template_seat_type_option, price: -1000) }

    let(:seat_type) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type) }

    let(:master_seat_area) { create(:master_seat_area, area_name: 'D', position: 'レギュラーシート', area_code: 'D') }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale, master_seat_area: master_seat_area) }

    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, row: 6, seat_number: 30) }

    let(:order) { create(:order, total_price: total_price, seat_sale: seat_sale, user: sales_logged_in_user) }
    let(:payment) { create(:payment, order: order, charge_id: charge_id, payment_progress: :captured) }
    let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type, template_seat_type_option: template_seat_type_option) }
    let(:total_price) { 4000 }
    let(:charge_id) { 'charge_id' }

    context '完了画面に遷移した場合' do
      it 'レスポンスにチケット情報が含まれていること' do
        request_purchase_complete
        res_order_id = Rails.env.production? ? order.id : "#{Rails.env}#{order.id}"

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data['totalPrice']).to eq(4000)
        expect(data['transactionId']).to eq(res_order_id)
        expect(data['transactionProducts'][0]['name']['promoterYear']).to eq(2020)
        expect(data['transactionProducts'][0]['name']['period']).to eq('autumn')
        expect(data['transactionProducts'][0]['name']['round']).to eq(5)
        expect(data['transactionProducts'][0]['name']['highPriorityEventName']).to eq('T')
        expect(data['transactionProducts'][0]['sku']).to eq('D レギュラーシート 6列30番')
        expect(data['transactionProducts'][0]['price']).to eq(4000)
        expect(data['transactionProducts'][0]['quantity']).to eq(1)
      end
    end

    context 'TicketReserveが３つある場合（requesting_paymentが２つ、capturedが１つあるケース）' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: nil)
        create(:payment, order: order1, payment_progress: :requesting_payment, charge_id: '1')
        create(:payment, order: order2, payment_progress: :requesting_payment, charge_id: '2')
      end

      let(:order1) { create(:order, order_type: :purchase, user: sales_logged_in_user, seat_sale: seat_sale) }
      let(:order2) { create(:order, order_type: :purchase, user: sales_logged_in_user, seat_sale: seat_sale) }
      let(:template_seat_type_option) { create(:template_seat_type_option, price: -500) }
      let(:total_price) { 4500 }

      it 'レスポンスにチケット情報が含まれていること' do
        request_purchase_complete
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        res_order_id = Rails.env.production? ? order.id : "#{Rails.env}#{order.id}"

        expect(data['totalPrice']).to eq(4500)
        expect(data['transactionId']).to eq(res_order_id)
        expect(data['transactionProducts'][0]['name']['promoterYear']).to eq(2020)
        expect(data['transactionProducts'][0]['name']['period']).to eq('autumn')
        expect(data['transactionProducts'][0]['name']['round']).to eq(5)
        expect(data['transactionProducts'][0]['name']['highPriorityEventName']).to eq('T')
        expect(data['transactionProducts'][0]['sku']).to eq('D レギュラーシート 6列30番')
        expect(data['transactionProducts'][0]['price']).to eq(4500)
        expect(data['transactionProducts'][0]['quantity']).to eq(1)
      end
    end

    context 'already_capture_errorでpaymentがwaiting_capture状態で完了画面まできた場合' do
      before do
        payment.update(payment_progress: :waiting_capture)
      end

      it 'レスポンスが空で返ること' do
        request_purchase_complete

        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)
        expect(data).to eq({})
      end
    end
  end
end
