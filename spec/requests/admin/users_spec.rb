# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users', :admin_logged_in, type: :request do
  describe 'GET admin/users/search' do
    subject(:search_user) { get admin_search_user_url, params: params }

    let(:profile) { create(:profile) }
    let(:phone_number) { profile.phone_number }
    let(:family_name_kana) { profile.family_name_kana }
    let(:given_name_kana) { profile.given_name_kana }
    let(:params) do
      {
        phone_number: phone_number,
        family_name_kana: family_name_kana,
        given_name_kana: given_name_kana
      }
    end

    context '対象がある検索条件の場合' do
      it 'ユーザーのプロフィール情報が返ってくること' do
        search_user

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(profile.user.id)
        expect(json['sixgramId']).to eq(profile.user.sixgram_id)
        expect(json['emailVerified']).to eq(profile.user.email_verified)
        expect(json['familyName']).to eq(profile.family_name)
        expect(json['givenName']).to eq(profile.given_name)
        expect(json['familyNameKana']).to eq(profile.family_name_kana)
        expect(json['givenNameKana']).to eq(profile.given_name_kana)
        expect(json['birthday']).to eq(profile.birthday.to_s)
        expect(json['email']).to eq(profile.email)
        expect(json['zipCode']).to eq(profile.zip_code)
        expect(json['prefecture']).to eq(profile.prefecture)
        expect(json['city']).to eq(profile.city)
        expect(json['addressLine']).to eq(profile.address_line)
        expect(json['phoneNumber']).to eq(profile.phone_number)
      end
    end

    context '指定した電話番号のプロフィールがないとき' do
      let(:phone_number) { '09000000000' }

      it '見つからないのでエラーが返ってくること' do
        search_user
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(json['code']).to eq('phone_number')
        expect(json['detail']).to eq('ユーザーが見つかりません。')
      end
    end

    context '姓（カタカナ）が一致しないとき' do
      let(:family_name_kana) { 'test' }

      it 'エラーが返ってくること' do
        search_user
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['code']).to eq('family_name_kana')
        expect(json['detail']).to eq('姓（カタカナ）が一致しません。')
      end
    end

    context '名（カタカナ）が一致しないとき' do
      let(:given_name_kana) { 'test' }

      it 'エラーが返ってくること' do
        search_user
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['code']).to eq('given_name_kana')
        expect(json['detail']).to eq('名（カタカナ）が一致しません。')
      end
    end
  end

  describe 'GET admin/users/orders' do
    subject(:order_index) do
      order = create(:order, :with_ticket_and_build_reserves, user: user, order_at: Time.zone.now)
      create(:payment, order: order)
      get admin_orders_user_url(user.id, format: :json)
    end

    let(:user) { create(:user) }

    it 'HTTPステータスが200であること' do
      order_index
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.length).to eq user.orders.length
    end

    it 'json[:orders]は::OrderSerializerの属性を持つハッシュであること' do
      order_index
      json = JSON.parse(response.body)[0]
      expect_data = %w[id total_price created_at payment_status returned_at daily_no hold_name_jp event_date ticket_count].map { |key| key.camelize(:lower) }
      expect(expect_data).to include_keys(json.keys)
    end

    it '申込の開催デイリの情報の確認' do
      order_index
      json = JSON.parse(response.body)[0]
      hold_daily_schedule = user.tickets.first.seat_type.seat_sale.hold_daily_schedule
      expect(json['dailyNo']).to eq(hold_daily_schedule.daily_no)
      expect(json['holdNameJp']).to eq(hold_daily_schedule.hold_name_jp)
    end

    it 'orderのorder_typeがpurchaseの分のみが返されること' do
      10.times do |_n|
        order = create(:order, :with_ticket_and_build_reserves, user: user, order_at: Time.zone.now, order_type: [0, 1].sample)
        create(:payment, order: order)
      end
      order_index
      count = Order.purchase.count
      json = JSON.parse(response.body)
      expect(json.count).to eq(count)
    end
  end

  describe 'GET admin/users/ticket_reserves' do
    subject(:ticket_reserves) do
      get admin_ticket_reserves_user_url(user.id)
    end

    let(:user) { create(:user) }
    let(:seat_sale) { create(:seat_sale, :in_term) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user) }
    let(:payment) { create(:payment, payment_progress: 4) }
    let(:order) { create(:order, user: user, seat_sale: seat_sale, payment: payment, order_type: 0) }

    before do
      create(:ticket_reserve, order: order, ticket: ticket)
    end

    context 'ユーザーが所持しているチケット' do
      it 'HTTPステータスが200であること' do
        ticket_reserves
        expect(response).to have_http_status(:ok)
      end

      it '想定しているjsonレスポンスが返ってくること' do
        seat_type_option = create(:seat_type_option)
        ticket.ticket_reserves.first.update(seat_type_option_id: seat_type_option.id)
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
        expect(json['optionTitle']).to eq(seat_type_option.title)
      end
    end

    context 'ユーザーが所持しているチケットが入場期限内の場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it '想定しているjsonレスポンスが返ってくること' do
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ユーザーが所持しているチケットが入場期限外の場合' do
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it '想定しているjsonレスポンスが返ってくること' do
        ticket_reserves
        json = JSON.parse(response.body)
        expect(json.count).to eq(0)
      end
    end

    context 'ユーザーが所持しているチケットが譲渡中の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        ticket.sold!
        ticket.sold_ticket_uuid_generate!
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ユーザーが所持しているチケットが譲渡完了の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        TicketReserve.first.update(transfer_at: Time.zone.now - 1.day)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ユーザーが所持しているチケットが購入済み以外のステータスの場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        Payment.update(payment_progress: 5)
        ticket_reserves
        json = JSON.parse(response.body)
        expect(json.count).to eq(0)
      end
    end

    context 'ユーザーが所持しているチケットが譲渡の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        Order.update(order_type: 1)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end

    context 'ユーザーが所持しているチケットが管理者譲渡の場合' do
      it '想定しているjsonレスポンスが返ってくること' do
        Order.update(order_type: 2)
        ticket_reserves
        json = JSON.parse(response.body)[0]
        expect(json['id']).to eq(TicketReserve.first.id)
      end
    end
  end

  describe 'PUT admin/users/:id/send_unsubscribe_mail' do
    subject(:send_unsubscribe_mail) { put admin_send_unsubscribe_mail_url(id: profile.user_id) }

    let(:profile) { create(:profile) }

    it '認証メールが送信されること' do
      expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { send_unsubscribe_mail } }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】退会手続きのご案内'
    end

    it '退会したユーザーの場合が送信されないこと' do
      target_user = User.find(profile.user_id)
      target_user.update!(deleted_at: Time.zone.now)
      send_unsubscribe_mail
      json = JSON.parse(response.body)
      expect(json['detail']).to eq('退会したユーザーです。')
    end
  end

  describe 'GET /csv_export' do
    subject(:export_csv) { get admin_users_export_csv_url(format: :json) }

    before do
      create_list(:user, 10, :with_profile)
    end

    it 'userテーブルの情報を取得できる' do
      export_csv
      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(10)
    end

    it '想定の属性を持つハッシュであること' do
      export_csv
      json = JSON.parse(response.body)
      arr = %w[id sixgramId phoneNumber email mailmagazine familyName givenName familyNameKana givenNameKana
               birthday zipCode prefecture city addressLine addressDetail ngUserCheck createdAt deletedAt].map { |key| key.to_s.camelize(:lower) }
      json.all? { |hash| expect(hash.keys).to match_array(arr) }
    end
  end
end
