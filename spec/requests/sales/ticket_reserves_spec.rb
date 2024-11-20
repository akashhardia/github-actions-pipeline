# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TicketReserves', type: :request do
  describe 'GET ticket_reserves', :sales_logged_in do
    subject(:ticket_reserves) do
      get sales_ticket_reserves_url
    end

    before do
      create(:ticket_reserve, order: order, ticket: ticket)
    end

    let(:seat_sale) { create(:seat_sale, :in_term) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: sales_logged_in_user) }
    let(:order) { create(:order, user: sales_logged_in_user, seat_sale: seat_sale, payment: payment) }
    let(:payment) { create(:payment, payment_progress: 4) }

    context 'ログインユーザーが所持しているチケット' do
      it 'HTTPステータスが200であること' do
        ticket_reserves
        expect(response).to have_http_status(:ok)
      end

      it '想定しているjsonレスポンスが返ってくること' do
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ログインユーザーが所持しているチケットが入場期限内の場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it '想定しているjsonレスポンスが返ってくること' do
        get sales_ticket_reserves_url
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ログインユーザーが所持しているチケットが入場期限外の場合' do
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it '想定しているjsonレスポンスが返ってくること' do
        get sales_ticket_reserves_url
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context 'ログインユーザーが所持しているチケットが譲渡中の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        ticket.sold!
        ticket.sold_ticket_uuid_generate!
        get sales_ticket_reserves_url
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ログインユーザーが所持しているチケットが譲渡完了の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        TicketReserve.first.update(transfer_at: Time.zone.now - 1.day)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context '購入済みステータス以外の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        Payment.update(payment_progress: 5)
        ticket_reserves
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context '譲渡のチケットの場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        Order.update(order_type: 1)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context '管理画面譲渡のチケットの場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        Order.update(order_type: 2)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end
  end

  describe 'GET ticket_reserve/:id', :sales_logged_in do
    subject(:get_ticket_reserve) do
      get sales_ticket_reserve_url(id: ticket_reserve.id)
    end

    let(:seat_sale) { create(:seat_sale, :in_term) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: sales_logged_in_user) }
    let(:order) { create(:order, user: sales_logged_in_user, seat_sale: seat_sale) }
    let(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket) }

    context 'ログインユーザーが所持しているチケット' do
      it 'HTTPステータスが200であること' do
        get_ticket_reserve
        expect(response).to have_http_status(:ok)
      end

      it '想定しているjsonレスポンスが返ってくること' do
        get_ticket_reserve
        json = JSON.parse(response.body)
        expect(json['ticketReserve']['id']).to eq(ticket_reserve.id)
        expect(json['profile']['fullName']).to eq(sales_logged_in_user.profile.full_name)
      end
    end

    context 'ログインユーザーが所持していないチケット' do
      let(:another_user) { create(:user) }
      let(:another_order) { create(:order, :with_ticket_reserve_in_admission, user: another_user) }

      it 'HTTPステータスが400であること' do
        get sales_ticket_reserve_url(id: another_order.ticket_reserves.first.id)
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('所持チケットではありません')
      end
    end

    context 'チケットが譲渡済みで所有権が他のユーザーにある場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: another_user) }
      let(:another_user) { create(:user) }

      it 'HTTPステータスが400であること' do
        get_ticket_reserve
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'ログインユーザーが所持しているチケットが入場期限内の場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it '想定しているjsonレスポンスが返ってくること' do
        get_ticket_reserve
        json = JSON.parse(response.body)
        expect(json['ticketReserve']['id']).to eq(ticket_reserve.id)
      end
    end

    context 'ログインユーザーが所持しているチケットが入場期限外の場合' do
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it '想定しているjsonレスポンスが返ってくること' do
        get_ticket_reserve
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('入場期限が過ぎています')
      end
    end

    context 'ログインユーザーが所持しているチケットが譲渡中の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        ticket.sold!
        ticket.sold_ticket_uuid_generate!
        get_ticket_reserve
        json = JSON.parse(response.body)
        expect(json['ticketReserve']['id']).to eq(ticket_reserve.id)
      end
    end

    context 'ログインユーザーが所持しているチケットが譲渡完了の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        ticket_reserve.update(transfer_at: Time.zone.now - 1.day)
        get_ticket_reserve
        json = JSON.parse(response.body)
        expect(json['ticketReserve']['id']).to eq(ticket_reserve.id)
      end
    end

    # TODO: NGユーザーチェックスキップ
    # context 'NGユーザーだった場合' do
    #   let(:sales_logged_in_user_sixgram_id) { '09000010002' }

    #   it '403エラーが発生する前に、ログインできない' do
    #     get_ticket_reserve
    #     expect(response).to have_http_status(:unauthorized)
    #     body = JSON.parse(response.body)
    #     expect(body['code']).to eq('login_required')
    #     expect(session[:user_auth_token].present?).to be false
    #   end
    # end

    context 'ユーザーのqr_user_idが作成されることの確認' do
      it 'qr_user_idがnilが場合、qr_user_idが作成されること' do
        sales_logged_in_user.update!(qr_user_id: nil)
        expect { get_ticket_reserve }.to change { sales_logged_in_user.reload.qr_user_id }
      end

      it 'qr_user_idがある場合、qr_user_idが作成されないこと' do
        expect { get_ticket_reserve }.not_to change { sales_logged_in_user.reload.qr_user_id }
      end
    end

    context 'seat_area.entranceが存在する場合' do
      let(:track_x) { create(:track, track_code: '01', name: '競技場X') }
      let(:entrance_a) { create(:entrance, name: '入場口A', track: track_x) }

      before do
        seat_area.update(entrance: entrance_a)
      end

      it 'trackNameに競技場名が出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['trackName']).to eq(track_x.name)
      end

      it 'entranceNameに入場口名が出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['entranceName']).to eq(entrance_a.name)
      end
    end

    context 'seat_area.entranceがnilの場合' do
      before do
        seat_area.update(entrance: nil)
      end

      it 'trackNameにnilが出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['trackName']).to eq(nil)
      end

      it 'entranceNameにnilが出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['entranceName']).to eq(nil)
      end
    end

    context 'オプションなしの場合' do
      before do
        ticket_reserve.update(seat_type_option: nil)
      end

      it 'discountedPriceは通常価格が出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['discountedPrice']).to eq(seat_type.price)
      end

      it 'オプション名は "-" が出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['optionTitle']).to eq('-')
      end
    end

    context 'オプションが選択されている場合' do
      let(:template_seat_type_option) { create(:template_seat_type_option, price: -500) }
      let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type, template_seat_type_option: template_seat_type_option) }

      before do
        ticket_reserve.update(seat_type_option: seat_type_option)
      end

      it 'discountedPriceは割引後の価格が出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)

        expect(json['ticketReserve']['discountedPrice']).to eq(seat_type.price + template_seat_type_option.price)
        expect(json['ticketReserve']['discountedPrice']).to eq(500)
      end
    end

    context 'クーポンが利用された場合' do
      let(:coupon) { create(:coupon) }
      let(:user_coupon) { create(:user_coupon, coupon: coupon) }
      let(:order) { create(:order, user: sales_logged_in_user, seat_sale: seat_sale, user_coupon: user_coupon) }

      it 'クーポン情報が出力されること' do
        get_ticket_reserve
        json = JSON.parse(response.body)
        expect(json['ticketReserve']['coupon']['title']).to eq(coupon.title)
        expect(json['ticketReserve']['coupon']['rate']).to eq(coupon.rate)
      end
    end

    context 'キャンペーンが利用された場合' do
      let(:campaign) { create(:campaign) }

      it 'キャンペーン情報が出力されること' do
        create(:campaign_usage, campaign: campaign, order: order)
        get_ticket_reserve
        json = JSON.parse(response.body)
        expect(json['ticketReserve']['campaign']['title']).to eq(campaign.title)
        expect(json['ticketReserve']['campaign']['discountRate']).to eq(campaign.discount_rate)
      end
    end
  end

  describe 'GET ticket_reserves/:id/transfer_uuid', :sales_logged_in do
    subject(:get_transfer_uuid) do
      get sales_transfer_uuid_path(id: ticket_reserve.id)
    end

    let(:seat_sale) { create(:seat_sale, :in_term) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: sales_logged_in_user) }
    let(:order) { create(:order, user: sales_logged_in_user, seat_sale: seat_sale) }
    let(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket) }

    context 'transfer_uuidがnilの場合' do
      it 'HTTPステータスが400であること' do
        get_transfer_uuid
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('URLが無効です。')
      end
    end

    context 'transfer_uuidがnilじゃ無い場合' do
      before do
        ticket_reserve.ticket.transfer_uuid = 'ABCDabcd1234'
        ticket_reserve.ticket.save
      end

      it 'HTTPステータスが200であること' do
        get_transfer_uuid
        expect(response).to have_http_status(:ok)
      end

      it '正しいデータが返ってくること' do
        get_transfer_uuid
        json = JSON.parse(response.body)
        expect(json).to eq({ 'transferUuid' => 'ABCDabcd1234' })
      end

      context 'ユーザーがチケット所有者では無い場合' do
        let(:another_user) { create(:user) }

        before do
          ticket_reserve.ticket.user_id = another_user.id
          ticket_reserve.ticket.save
        end

        it 'HTTPステータスが400であること' do
          get_transfer_uuid
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('所持チケットではありません')
        end
      end

      context '入場期限が過ぎている場合' do
        let(:after_closing_seat_sale) { create(:seat_sale, :after_closing) }

        before do
          ticket_reserve.ticket.seat_type.seat_sale_id = after_closing_seat_sale.id
          ticket_reserve.ticket.seat_type.save
        end

        it 'HTTPステータスが400であること' do
          get_transfer_uuid
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('入場期限が過ぎています')
        end
      end

      context 'すでに入場している場合' do
        before do
          create(:ticket_log, ticket: ticket, result_status: :entered)
        end

        it 'HTTPステータスが400であること' do
          get_transfer_uuid
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('すでに入場しています')
        end
      end

      context '未入場の場合' do
        before do
          create(:ticket_log, ticket: ticket, result_status: :before_enter)
        end

        it '正常終了すること' do
          get_transfer_uuid
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
