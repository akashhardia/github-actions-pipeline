# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tickets', :admin_logged_in, type: :request do
  describe 'GET admin/tickets/:id/info' do
    subject(:get_ticket_info) { get admin_ticket_info_url(ticket.id) }

    let(:ticket) { create(:ticket, qr_ticket_id: 'test', user: user) }
    let(:user) { create(:user, qr_user_id: 'test') }

    context '存在するチケットを指定したとき' do
      it 'チケットの付加情報が返ってくること' do
        get_ticket_info

        json = JSON.parse(response.body)

        expect(json['qrUserId']).to eq(user.qr_user_id)
      end
    end
  end

  describe 'PUT /tickets/stop_selling' do
    subject(:ticket_stop_selling) { put admin_ticket_stop_selling_url, params: params }

    let(:ticket1) { create(:ticket, seat_type: seat_type) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term, :available) }

    let(:params) { { ticket_ids: ticket_ids } }
    let(:ticket_ids) { [ticket1.id] }

    it '変更したチケット情報を返すこと' do
      ticket_stop_selling
      data = JSON.parse(response.body)
      expect_data = %w[id status seatNumber salesType masterSeatUnitId unitType unitName]
      expect(expect_data).to include_keys(data.first.keys)
    end

    context 'チケット一枚を指定した場合' do
      it 'statusがnot_for_saleに更新されていること' do
        expect { ticket_stop_selling }.to change { ticket1.reload.status }.from('available').to('not_for_sale')
      end
    end

    context 'チケット複数枚を指定した場合' do
      let(:ticket2) { create(:ticket, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it 'statusが全てnot_for_saleに更新されていること' do
        expect { ticket_stop_selling }.to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.status == 'not_for_sale' }
        }.from(false).to(true)
      end
    end

    context '販売済みのチケットが含まれている場合' do
      let(:ticket2) { create(:ticket, seat_type: seat_type, status: :sold) }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it 'statusが更新されないこと' do
        expect { ticket_stop_selling }.not_to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.status == 'not_for_sale' }
        }
      end
    end

    context '存在しないticket_idが含まれている場合' do
      let(:ticket_ids) { [ticket1.id, ticket1.id + 1] }

      it 'エラーが発生すること' do
        ticket_stop_selling
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(body['detail']).to eq('存在しないチケットが含まれています')
      end
    end
  end

  describe 'PUT /tickets/release_from_stop_selling' do
    subject(:ticket_release_from_stop_selling) { put admin_ticket_release_from_stop_selling_url, params: params }

    let(:ticket1) { create(:ticket, seat_type: seat_type) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term, :available) }

    let(:params) { { ticket_ids: ticket_ids } }
    let(:ticket_ids) { [ticket1.id] }

    context 'チケット一枚を指定した場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
      end

      it '変更したチケット情報を返すこと' do
        ticket_release_from_stop_selling
        data = JSON.parse(response.body)
        expect_data = %w[id status seatNumber salesType masterSeatUnitId unitType unitName]
        expect(expect_data).to include_keys(data.first.keys)
      end

      it 'statusがavailableに更新されていること' do
        expect { ticket_release_from_stop_selling }.to change { ticket1.reload.status }.from('not_for_sale').to('available')
      end
    end

    context 'チケット複数枚を指定した場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
      end

      let(:ticket2) { create(:ticket, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it 'statusが全てnot_for_saleに更新されていること' do
        expect { ticket_release_from_stop_selling }.to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.status == 'available' }
        }.from(false).to(true)
      end
    end

    context '譲渡中のチケットが含まれている場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
      end

      let(:ticket2) { create(:ticket, seat_type: seat_type, transfer_uuid: 'test') }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it 'statusが更新されないこと' do
        expect { ticket_release_from_stop_selling }.not_to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.status == 'not_for_sale' }
        }
      end
    end

    context '存在しないticket_idが含まれている場合' do
      let(:ticket_ids) { [ticket1.id, ticket1.id + 1] }

      it 'エラーが発生すること' do
        ticket_release_from_stop_selling
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(body['detail']).to eq('存在しないチケットが含まれています')
      end
    end
  end

  describe 'PUT /tickets/transfer' do
    subject(:ticket_transfer) { put admin_ticket_transfer_url, params: params }

    let(:ticket1) { create(:ticket, seat_type: seat_type) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term, :available) }

    let(:params) { { ticket_ids: ticket_ids } }
    let(:ticket_ids) { [ticket1.id] }

    context 'チケット一枚を指定した場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
      end

      it '変更したチケット情報を返すこと' do
        ticket_transfer
        data = JSON.parse(response.body)
        expect_data = %w[id status seatNumber salesType masterSeatUnitId unitType unitName]
        expect(expect_data).to include_keys(data.first.keys)
      end

      it '譲渡idが発行されていること' do
        expect { ticket_transfer }.to change { ticket1.reload.transfer_uuid.present? }.from(false).to(true)
      end
    end

    context 'チケット複数枚を指定した場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
      end

      let(:ticket2) { create(:ticket, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it '譲渡idが全て発行されていること' do
        expect { ticket_transfer }.to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.transfer_uuid.present? }
        }.from(false).to(true)
      end
    end

    context '譲渡中のチケットが含まれている場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
      end

      let(:ticket2) { create(:ticket, seat_type: seat_type, transfer_uuid: 'test') }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it '譲渡idが発行されないこと' do
        expect { ticket_transfer }.not_to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.transfer_uuid.present? }
        }
      end
    end

    context '存在しないticket_idが含まれている場合' do
      let(:ticket_ids) { [ticket1.id, ticket1.id + 1] }

      it 'エラーが発生すること' do
        ticket_transfer
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(body['detail']).to eq('存在しないチケットが含まれています')
      end
    end
  end

  describe 'PUT /tickets/transfer_cancel' do
    subject(:ticket_transfer_cancel) { put admin_ticket_transfer_cancel_url, params: params }

    let(:ticket1) { create(:ticket, seat_type: seat_type) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term, :available) }

    let(:params) { { ticket_ids: ticket_ids } }
    let(:ticket_ids) { [ticket1.id] }

    context 'チケット一枚を指定した場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
        put admin_ticket_transfer_url, params: params
      end

      it '変更したチケット情報を返すこと' do
        ticket_transfer_cancel
        data = JSON.parse(response.body)
        expect_data = %w[id status seatNumber salesType masterSeatUnitId unitType unitName]
        expect(expect_data).to include_keys(data.first.keys)
      end

      it '譲渡idが空になっていること' do
        expect { ticket_transfer_cancel }.to change { ticket1.reload.transfer_uuid.blank? }.from(false).to(true)
      end
    end

    context 'チケット複数枚を指定した場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
        put admin_ticket_transfer_url, params: params
      end

      let(:ticket2) { create(:ticket, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it '譲渡idが全て空になっていること' do
        expect { ticket_transfer_cancel }.to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.transfer_uuid.blank? }
        }.from(false).to(true)
      end
    end

    context '販売済みのチケットが含まれている場合' do
      before do
        put admin_ticket_stop_selling_url, params: params
        put admin_ticket_transfer_url, params: params
        ticket2.sold!
      end

      let(:ticket2) { create(:ticket, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_type: seat_type) }

      let(:ticket_ids) { [ticket1.id, ticket2.id, ticket3.id] }

      it '譲渡idが発行されないこと' do
        expect { ticket_transfer_cancel }.not_to change {
          [ticket1, ticket2, ticket3].all? { |ticket| ticket.reload.transfer_uuid.blank? }
        }
      end
    end

    context '存在しないticket_idが含まれている場合' do
      let(:ticket_ids) { [ticket1.id, ticket1.id + 1] }

      it 'エラーが発生すること' do
        ticket_transfer_cancel
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(body['detail']).to eq('存在しないチケットが含まれています')
      end
    end
  end

  describe 'GET admin/tickets' do
    subject(:get_tickets) { get admin_tickets_index_url, params: { today: today, qr_ticket_id: qr_ticket_id } }

    let(:ticket) { create(:ticket, qr_ticket_id: 'test', user: user) }
    let(:user) { create(:user, qr_user_id: 'test') }
    let(:qr_ticket_id) { ticket.qr_ticket_id }
    let(:today) { false }
    let(:seat_type_option) { create(:seat_type_option) }
    let(:ticket_reserve) { create(:ticket_reserve, ticket: ticket, seat_type_option: seat_type_option) }
    let(:payment) { create(:payment, order: ticket_reserve.order, payment_progress: :captured) }

    before do
      ticket.update(current_ticket_reserve_id: ticket_reserve.id)
    end

    context '対象のチケットが含まれる検索条件の場合' do
      it 'チケットの情報が返ってくること' do
        payment
        get_tickets

        json = JSON.parse(response.body)[0]
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['qrTicketId']).to eq(ticket.qr_ticket_id)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily.hold.hold_name_jp)
        expect(json['dailyNo']).to eq(HoldDailySchedule::DAILY_NO[ticket.seat_sale.hold_daily_schedule.daily_no.to_sym])
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily.event_date.to_s)
        expect(json['admissionTime']).to eq(ticket.seat_sale.admission_available_at.strftime('%H:%M'))
        expect(json['ticketStatus']).to eq('before_enter')
        expect(json['userStatus']).to eq(nil)
        expect(json['updatedAt']).to be_present
        expect(json['optionTitle']).to eq(seat_type_option.title)
      end

      it 'チケットログがresult=falseは無視してステータスが返ってくること' do
        seat_type_option = create(:seat_type_option)
        create(:ticket_reserve, ticket: ticket, seat_type_option: seat_type_option)
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :entered)
        create(:ticket_log, ticket: ticket, result: 'false', result_status: :left)
        get_tickets

        json = JSON.parse(response.body)[0]
        expect(json['ticketStatus']).to eq('entered')
      end
    end

    context 'todayがtrueの場合は、本日入場のチケットが対象となること' do
      let(:today) { true }

      it '見つからないのでエラーが返ってくること' do
        ticket.seat_sale.update_columns(admission_available_at: Time.zone.now + 10.days)
        get_tickets
        json = JSON.parse(response.body)
        expect(json['code']).to eq('qr_ticket_id_error')
        expect(json['detail']).to eq('チケットが見つかりませんでした')
      end

      it 'チケットの情報が返って来ること' do
        ticket.seat_sale.update(admission_available_at: Time.zone.now)
        get_tickets
        json = JSON.parse(response.body)
        expect(json.size).to eq(1)
      end
    end

    context 'qr_ticket_idが空の場合' do
      let(:qr_ticket_id) { nil }

      it 'エラーが返ってくること' do
        get_tickets
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('qr_ticket_id_error')
        expect(json['detail']).to eq('チケット番号は必須です')
      end
    end

    context 'qr_ticket_idの対象チケットがない場合' do
      let(:qr_ticket_id) { 9999 }

      it 'エラーが返ってくること' do
        get_tickets
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('qr_ticket_id_error')
        expect(json['detail']).to eq('チケットが見つかりませんでした')
      end
    end

    context '管理画面から譲渡の場合' do
      let(:seat_type_option) { create(:seat_type_option) }
      let(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket, seat_type_option: seat_type_option) }
      let(:ticket) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: 'test') }
      let(:order) { create(:order, order_type: :admin_transfer, user: user) }

      it '該当のチケット情報が返されること' do
        ticket_reserve
        get_tickets

        json = JSON.parse(response.body)[0]
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['qrTicketId']).to eq(ticket.qr_ticket_id)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily.hold.hold_name_jp)
        expect(json['dailyNo']).to eq(HoldDailySchedule::DAILY_NO[ticket.seat_sale.hold_daily_schedule.daily_no.to_sym])
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily.event_date.to_s)
        expect(json['admissionTime']).to eq(ticket.seat_sale.admission_available_at.strftime('%H:%M'))
        expect(json['ticketStatus']).to eq('before_enter')
        expect(json['userStatus']).to eq(nil)
        expect(json['updatedAt']).to be_present
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option.title)
      end
    end

    context 'TicketReserveが３つある場合（requesting_paymentが２つ、capturedが１つあるケース）' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: nil)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :requesting_payment)
        create(:payment, order: order3, payment_progress: :captured)
      end

      let(:seat_type_option) { create(:seat_type_option) }
      let(:ticket_reserve) { create(:ticket_reserve, order: order3, ticket: ticket, seat_type_option: seat_type_option) }
      let(:ticket) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: 'test') }
      let(:order1) { create(:order, order_type: :purchase, user: user) }
      let(:order2) { create(:order, order_type: :purchase, user: user) }
      let(:order3) { create(:order, order_type: :purchase, user: user) }

      it '該当のチケット情報が返されること' do
        ticket_reserve
        get_tickets

        json = JSON.parse(response.body)[0]
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['qrTicketId']).to eq(ticket.qr_ticket_id)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily.hold.hold_name_jp)
        expect(json['dailyNo']).to eq(HoldDailySchedule::DAILY_NO[ticket.seat_sale.hold_daily_schedule.daily_no.to_sym])
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily.event_date.to_s)
        expect(json['admissionTime']).to eq(ticket.seat_sale.admission_available_at.strftime('%H:%M'))
        expect(json['ticketStatus']).to eq('before_enter')
        expect(json['userStatus']).to eq(nil)
        expect(json['updatedAt']).to be_present
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option.title)
      end
    end

    context 'TicketReserveに譲渡がある場合' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: seat_type_option, transfer_at: Time.zone.now)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :captured)
      end

      let(:user2) { create(:user, qr_user_id: 'test2') }
      let(:seat_type_option) { create(:seat_type_option) }
      let(:ticket_reserve) { create(:ticket_reserve, order: order3, ticket: ticket, seat_type_option: nil) }
      let(:ticket) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user2, qr_ticket_id: 'test') }
      let(:order1) { create(:order, order_type: :purchase, user: user) }
      let(:order2) { create(:order, order_type: :purchase, user: user) }
      let(:order3) { create(:order, order_type: :transfer, user: user2) }

      it '該当のチケット情報が返されること' do
        ticket_reserve
        get_tickets

        json = JSON.parse(response.body)[0]
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['qrTicketId']).to eq(ticket.qr_ticket_id)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily.hold.hold_name_jp)
        expect(json['dailyNo']).to eq(HoldDailySchedule::DAILY_NO[ticket.seat_sale.hold_daily_schedule.daily_no.to_sym])
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily.event_date.to_s)
        expect(json['admissionTime']).to eq(ticket.seat_sale.admission_available_at.strftime('%H:%M'))
        expect(json['ticketStatus']).to eq('before_enter')
        expect(json['userStatus']).to eq(nil)
        expect(json['updatedAt']).to be_present
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option&.title)
      end
    end
  end

  describe 'GET admin/tickets/:id' do
    subject(:get_ticket) { get admin_ticket_show_url(ticket.id) }

    let(:ticket) { create(:ticket, qr_ticket_id: 'test', user: user) }
    let(:ticket_reserve) { create(:ticket_reserve, ticket: ticket) }
    let(:user) { create(:user, qr_user_id: 'test') }
    let(:payment) { create(:payment, order: ticket_reserve.order, payment_progress: :captured) }

    before do
      ticket.update(current_ticket_reserve_id: ticket_reserve.id)
    end

    context '対象のチケットがある場合' do
      it 'チケットの情報が返ってくること' do
        ticket_reserve
        payment
        get_ticket

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['position']).to eq(ticket.position)
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option.title)
        expect(json['qrData']).to eq(%("test","test"))
        expect(json['areaName']).to eq(ticket.area_name)
        expect(json['position']).to eq(ticket.position)
        expect(json['row']).to eq(ticket.row)
        expect(json['seatNumber']).to eq(ticket.seat_number)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily_schedule.hold_name_jp)
        expect(json['dailyNo']).to eq('デイ')
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily_schedule.event_date.to_s)
        expect(json['eventTime']).to eq(ticket.hold_daily_schedule.opening_display)
        expect(json['status']).to eq('before_enter')
      end

      it 'チケットログがresult=falseは無視してステータスが返ってくること' do
        ticket_reserve
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :entered)
        create(:ticket_log, ticket: ticket, result: 'false', result_status: :left)
        get_ticket

        json = JSON.parse(response.body)
        expect(json['status']).to eq('entered')
      end
    end

    context '対象のチケットがない場合' do
      it 'not_foundエラーが返ってくること' do
        get admin_ticket_show_url(99999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'params[:detail]がついている場合' do
      it 'チケットの情報が返ってくること' do
        ticket_reserve
        get admin_ticket_show_url(ticket.id), params: { detail: true }

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['status']).to eq('before_enter')
        expect(json['admissionDisabledAt']).to be_nil
        expect(json['createdAt']).to be_present
        expect(json['updatedAt']).to be_present
      end

      it 'チケットログがresult=falseは無視してステータスが返ってくること' do
        ticket_reserve
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :entered)
        create(:ticket_log, ticket: ticket, result: 'false', result_status: :left)
        get admin_ticket_show_url(ticket.id), params: { detail: true }

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['status']).to eq('entered')
        expect(json['admissionDisabledAt']).to be_nil
        expect(json['createdAt']).to be_present
        expect(json['updatedAt']).to be_present
      end
    end

    context '管理画面から譲渡の場合' do
      let(:seat_type_option) { create(:seat_type_option) }
      let(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket, seat_type_option: seat_type_option) }
      let(:ticket) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: 'test') }
      let(:order) { create(:order, order_type: :admin_transfer, user: user) }

      it '該当のチケット情報が返されること' do
        ticket_reserve
        get_ticket

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['position']).to eq(ticket.position)
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option.title)
        expect(json['qrData']).to eq(%("test","test"))
        expect(json['areaName']).to eq(ticket.area_name)
        expect(json['position']).to eq(ticket.position)
        expect(json['row']).to eq(ticket.row)
        expect(json['seatNumber']).to eq(ticket.seat_number)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily_schedule.hold_name_jp)
        expect(json['dailyNo']).to eq('デイ')
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily_schedule.event_date.to_s)
        expect(json['eventTime']).to eq(ticket.hold_daily_schedule.opening_display)
        expect(json['status']).to eq('before_enter')
      end
    end

    context 'TicketReserveが３つある場合（requesting_paymentが２つ、capturedが１つあるケース）' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: nil)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :requesting_payment)
        create(:payment, order: order3, payment_progress: :captured)
      end

      let(:seat_type_option) { create(:seat_type_option) }
      let(:ticket_reserve) { create(:ticket_reserve, order: order3, ticket: ticket, seat_type_option: seat_type_option) }
      let(:ticket) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: 'test') }
      let(:order1) { create(:order, order_type: :purchase, user: user) }
      let(:order2) { create(:order, order_type: :purchase, user: user) }
      let(:order3) { create(:order, order_type: :purchase, user: user) }

      it '該当のチケット情報が返されること' do
        ticket_reserve
        get_ticket

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['position']).to eq(ticket.position)
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option.title)
        expect(json['qrData']).to eq(%("test","test"))
        expect(json['areaName']).to eq(ticket.area_name)
        expect(json['position']).to eq(ticket.position)
        expect(json['row']).to eq(ticket.row)
        expect(json['seatNumber']).to eq(ticket.seat_number)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily_schedule.hold_name_jp)
        expect(json['dailyNo']).to eq('デイ')
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily_schedule.event_date.to_s)
        expect(json['eventTime']).to eq(ticket.hold_daily_schedule.opening_display)
        expect(json['status']).to eq('before_enter')
      end
    end

    context 'TicketReserveに譲渡がある場合' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: seat_type_option, transfer_at: Time.zone.now)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :captured)
      end

      let(:user2) { create(:user, qr_user_id: 'test2') }
      let(:seat_type_option) { create(:seat_type_option) }
      let(:ticket_reserve) { create(:ticket_reserve, order: order3, ticket: ticket, seat_type_option: nil) }
      let(:ticket) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user2, qr_ticket_id: 'test') }
      let(:order1) { create(:order, order_type: :purchase, user: user) }
      let(:order2) { create(:order, order_type: :purchase, user: user) }
      let(:order3) { create(:order, order_type: :transfer, user: user2) }

      it '該当のチケット情報が返されること' do
        ticket_reserve
        get_ticket

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(ticket.id)
        expect(json['position']).to eq(ticket.position)
        expect(json['optionTitle']).to eq(ticket_reserve.seat_type_option&.title)
        expect(json['qrData']).to eq(%("test2","test"))
        expect(json['areaName']).to eq(ticket.area_name)
        expect(json['position']).to eq(ticket.position)
        expect(json['row']).to eq(ticket.row)
        expect(json['seatNumber']).to eq(ticket.seat_number)
        expect(json['holdNameJp']).to eq(ticket.seat_sale.hold_daily_schedule.hold_name_jp)
        expect(json['dailyNo']).to eq('デイ')
        expect(json['eventDate']).to eq(ticket.seat_sale.hold_daily_schedule.event_date.to_s)
        expect(json['eventTime']).to eq(ticket.hold_daily_schedule.opening_display)
        expect(json['status']).to eq('before_enter')
      end
    end
  end

  describe 'GET admin/tickets/:id/reserve_status' do
    subject(:get_ticket_reserve_status) { get admin_ticket_reserve_status_url(ticket.id) }

    let(:from_user) { create(:user, :with_profile) }
    let(:to_user) { create(:user) }

    let(:order_from) { create(:order, user: from_user) }
    let(:order_to) { create(:order, user: to_user) }

    let(:ticket) { create(:ticket, user: from_user) }

    let(:ticket_reserve_from) { create(:ticket_reserve, order: order_from, ticket: ticket, transfer_at: Time.zone.now, transfer_to_user_id: to_user.id) }
    let(:ticket_reserve_to) { create(:ticket_reserve, order: order_to, ticket: ticket, transfer_from_user_id: from_user.id) }

    context '対象のチケット譲渡ステータスがある場合' do
      it 'チケット譲渡ステータスの情報が返ってくること' do
        ticket_reserve_from
        ticket_reserve_to
        get_ticket_reserve_status
        json = JSON.parse(response.body)
        expect(json[0]['id']).to be_present
        expect(json[0]['transferAt']).to be_nil
        expect(json[1]['transferAt']).to be_present
        expect(json[0]['orderId']).to eq(order_to.id)
        expect(json[1]['orderId']).to eq(order_from.id)
        expect(json[0]['seatTypeOptionId']).to be_present
        expect(json[1]['seatTypeOptionId']).to be_present
        expect(json[0]['transferFromUserId']).to eq(from_user.id)
        expect(json[0]['transferToUserId']).to be_nil
        expect(json[1]['transferFromUserId']).to be_nil
        expect(json[1]['transferToUserId']).to eq(to_user.id)
        expect(json[0]['returnedAt']).to be_nil
        expect(json[1]['returnedAt']).to be_nil
        expect(json[0]['createdAt']).to be_present
        expect(json[0]['updatedAt']).to be_present
        expect(json[1]['createdAt']).to be_present
        expect(json[1]['updatedAt']).to be_present
      end
    end

    context '対象のチケット譲渡ステータスがない場合' do
      it '空が返ってくること' do
        get_ticket_reserve_status
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe 'GET admin/tickets/:id/logs' do
    subject(:get_ticket_logs) { get admin_ticket_logs_url(ticket.id) }

    let(:ticket) { create(:ticket) }
    let(:ticket_log1) { create(:ticket_log, ticket: ticket, device_id: '111') }
    let(:ticket_log2) { create(:ticket_log, ticket: ticket, device_id: '111') }

    context '対象のチケットログがある場合' do
      it 'チケットログの情報が返ってくること' do
        ticket_log1
        ticket_log2
        get_ticket_logs
        json = JSON.parse(response.body)
        expect(json[0]['id']).to eq(ticket_log2.id)
        expect(json[1]['id']).to eq(ticket_log1.id)
        expect(json[0]['ticketId']).to eq(ticket.id)
        expect(json[1]['ticketId']).to eq(ticket.id)
        expect(json[0]['logType']).to be_present
        expect(json[0]['requestStatus']).to be_present
        expect(json[0]['status']).to be_present
        expect(json[0]['result']).to be_present
        expect(json[0]['faceRecognition']).to be_present
        expect(json[0]['resultStatus']).to be_present
        expect(json[0]['failedMessage']).to be_present
        expect(json[0]['deviceId']).to be_present
        expect(json[0]['createdAt']).to be_present
        expect(json[0]['updatedAt']).to be_present
      end
    end

    context '対象のチケットログがない場合' do
      it '空が返ってくること' do
        get_ticket_logs
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe 'PUT admin/tickets/:id/before_enter' do
    subject(:ticket_before_enter) { put admin_ticket_before_enter_url(ticket.id) }

    let(:ticket) { create(:ticket, qr_ticket_id: '1') }
    let(:ticket_log) { create(:ticket_log, ticket: ticket, result_status: 'left', status: 'left', result: 'true') }

    context '対象のチケットがある場合' do
      it '成功すると未入場のticket_logが作成される' do
        ticket_log
        expect { ticket_before_enter }.to change { ticket.reload.ticket_logs.last.status }.from('left').to('before_enter').and change(TicketLog, :count).by(1)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['ticketStatus']).to eq('before_enter')
      end

      it '最新のticket_logが未入場の場合は、bad_requestが返ってくる' do
        ticket_log.update(status: 'before_enter', result_status: 'before_enter')
        ticket_before_enter
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('bad_request')
        expect(json['detail']).to eq('すでにチケットは未入場になっています')
      end

      it 'ticket_logがない場合は、bad_requestが返ってくる' do
        ticket.ticket_logs.destroy_all
        ticket_before_enter
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('bad_request')
        expect(json['detail']).to eq('すでにチケットは未入場になっています')
      end
    end

    context '対象のチケットがあり、顔認証情報が見つからない場合' do
      let(:ticket) { create(:ticket, qr_ticket_id: '3') }

      it 'not_foundが返ってくる' do
        ticket_log
        ticket_before_enter
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('not_found')
        expect(json['detail']).to eq('顔認証情報が見つかりません')
      end
    end

    context '対象のチケットがあり顔認証情報が失敗した場合' do
      let(:ticket) { create(:ticket, qr_ticket_id: '2') }

      it 'bad_requestが返ってくる' do
        ticket_log
        ticket_before_enter
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('bad_request')
        expect(json['detail']).to eq('顔認証削除が失敗しました')
      end
    end

    context '対象のチケットがQRコードが発行されていない場合' do
      let(:ticket) { create(:ticket, qr_ticket_id: nil) }

      it 'bad_requestエラーが返ってくること' do
        ticket_before_enter
        json = JSON.parse(response.body)
        expect(json['code']).to eq('bad_request')
        expect(json['detail']).to eq('QRコードが発行されていません')
      end
    end

    context '対象のチケットがない場合' do
      it 'not_foundエラーが返ってくること' do
        put admin_ticket_before_enter_url(99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT admin/tickets/:id/admission_disabled_at' do
    subject(:ticket_admission_disabled_at) { put admin_ticket_update_admission_disabled_at_url(ticket.id), params: params }

    context '対象のチケットが有効の場合' do
      let(:ticket) { create(:ticket, qr_ticket_id: 'test') }

      context 'updateActionをdisableにした場合' do
        let(:params) { { updateAction: 'disable' } }

        it 'disabled_atが埋まる' do
          expect { ticket_admission_disabled_at }.to change { ticket.reload.admission_disabled_at.present? }.from(false).to(true)
        end
      end

      context 'updateActionをenableにした場合' do
        let(:params) { { updateAction: 'enable' } }

        it 'bad_requestが返ってくる' do
          ticket.update(admission_disabled_at: nil)
          ticket_admission_disabled_at
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['code']).to eq('bad_request')
          expect(json['detail']).to eq('すでにチケットは有効になっています')
        end
      end
    end

    context '対象のチケットが無効の場合' do
      let(:ticket) { create(:ticket, admission_disabled_at: Time.zone.now, qr_ticket_id: 'test') }

      context 'updateActionをenableにした場合' do
        let(:params) { { updateAction: 'enable' } }

        it 'enabled_atがnilになる' do
          expect { ticket_admission_disabled_at }.to change { ticket.reload.admission_disabled_at.present? }.from(true).to(false)
        end
      end

      context 'updateActionをdisableにした場合' do
        let(:params) { { updateAction: 'disable' } }

        it 'bad_requestが返ってくる' do
          ticket.update(admission_disabled_at: Time.zone.now)
          ticket_admission_disabled_at
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['code']).to eq('bad_request')
          expect(json['detail']).to eq('すでにチケットは無効になっています')
        end
      end
    end

    context '対象のチケットがQRコードが発行されていない場合' do
      let(:ticket) { create(:ticket, qr_ticket_id: nil) }

      it 'bad_requestが返ってくる' do
        ticket_admission_disabled_at
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('bad_request')
        expect(json['detail']).to eq('QRコードが発行されていません')
      end
    end

    context '対象のチケットがない場合' do
      it 'not_foundエラーが返ってくること' do
        put admin_ticket_update_admission_disabled_at_url(99999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET admin/tickets/export_csv' do
    subject(:ticket_export_csv) do
      get admin_tickets_export_csv_url(format: :json), params: { seat_sale_ids: seat_sale_ids }
    end

    let!(:seat_sale_1) { create(:seat_sale) }
    let!(:seat_sale_2) { create(:seat_sale) }
    let!(:seat_sale_ids) { [seat_sale_1.id, seat_sale_2.id] }
    let!(:seat_type_1) { create(:seat_type, seat_sale: seat_sale_1) }
    let!(:seat_type_2) { create(:seat_type, seat_sale: seat_sale_2) }

    let(:user) { create(:user, :with_profile) }
    let!(:transfer_from_user) { create(:user) }
    let!(:purchase_order) { create(:order, id: 1, seat_sale: seat_sale_1, user_coupon_id: user_coupon.id) }
    let!(:transfer_order) { create(:order, id: 2, order_type: :transfer, seat_sale: seat_sale_1) }
    let!(:admin_transfer_order) { create(:order, id: 3, order_type: :admin_transfer, seat_sale: seat_sale_1) }
    let(:order1) { create(:order, id: 4, order_type: :purchase, user: user, seat_sale: seat_sale_2) }
    let(:order2) { create(:order, id: 5, order_type: :purchase, user: user, seat_sale: seat_sale_2) }
    let(:order3) { create(:order, id: 6, order_type: :purchase, user: user, seat_sale: seat_sale_2) }
    let(:order51) { create(:order, id: 7, order_type: :purchase, user: transfer_from_user, seat_sale: seat_sale_2) }
    let(:order52) { create(:order, id: 8, order_type: :purchase, user: transfer_from_user, seat_sale: seat_sale_2) }
    let(:order53) { create(:order, id: 9, order_type: :purchase, user: transfer_from_user, seat_sale: seat_sale_2) }
    let(:order53_transfer) { create(:order, id: 10, order_type: :transfer, user: user, seat_sale: seat_sale_2) }
    let(:order_irregular) { create(:order, id: 11, order_type: :purchase, user: user, seat_sale: seat_sale_2) }
    let(:order78) { create(:order, id: 12, order_type: :purchase, user: user, seat_sale: seat_sale_2, user_coupon_id: user_coupon.id) }
    # 購入のチケット
    let!(:sold_ticket_1) { create(:ticket, seat_type: seat_type_1, status: :sold, user: user) }
    # 譲渡のチケット
    let!(:sold_ticket_2) { create(:ticket, seat_type: seat_type_1, status: :sold, user: user) }
    # 管理者譲渡のチケット
    let!(:sold_ticket_3) { create(:ticket, seat_type: seat_type_2, status: :sold, user: user) }
    # TicketReserveが複数あるチケット（requesting_paymentが２件、capturedが１件）
    let!(:sold_ticket_4) { create(:ticket, seat_type: seat_type_2, status: :sold, user: user) }
    # TicketReserveが複数あって、最終的に譲渡されているチケット
    let!(:sold_ticket_5) { create(:ticket, seat_type: seat_type_2, status: :sold, user: user) }
    # soldで返金されているチケット（イレギュラーケース）
    let!(:sold_ticket_6) { create(:ticket, seat_type: seat_type_2, status: :sold, user: user) }
    # チケット２枚購入で１枚オプション設定あり、クーポン適用
    let!(:sold_ticket_7) { create(:ticket, seat_type: seat_type_2, status: :sold, user: user) }
    let!(:sold_ticket_8) { create(:ticket, seat_type: seat_type_2, status: :sold, user: user) }
    let(:seat_type_option) { create(:seat_type_option) }
    let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type_2, template_seat_type_option: template_seat_type_option) }
    let(:template_seat_type_option) { create(:template_seat_type_option, price: -500) }
    let(:template_coupon) { create(:template_coupon, rate: 10) }
    let(:user_coupon) { create(:user_coupon, coupon: create(:coupon, :available_coupon, template_coupon: template_coupon), user: user) }

    let!(:sold_ticket1_ticket_reserve) do
      tr = create(:ticket_reserve, order: purchase_order, ticket: sold_ticket_1, seat_type_option: nil)
      sold_ticket_1.update(current_ticket_reserve_id: tr.id, purchase_ticket_reserve_id: tr.id)
      tr
    end
    let!(:sold_ticket4_ticket_reserve) do
      tr = create(:ticket_reserve, order: order3, ticket: sold_ticket_4, seat_type_option: seat_type_option)
      sold_ticket_4.update(purchase_ticket_reserve_id: tr.id)
      tr
    end
    let!(:sold_ticket5_ticket_reserve) { create(:ticket_reserve, order: order53_transfer, ticket: sold_ticket_5, seat_type_option: seat_type_option2, transfer_from_user_id: transfer_from_user.id) }
    let!(:sold_ticket7_ticket_reserve) do
      tr = create(:ticket_reserve, order: order78, ticket: sold_ticket_7, seat_type_option: nil)
      sold_ticket_7.update(purchase_ticket_reserve_id: tr.id)
      tr
    end
    let!(:sold_ticket8_ticket_reserve) do
      tr = create(:ticket_reserve, order: order78, ticket: sold_ticket_8, seat_type_option: seat_type_option2)
      sold_ticket_8.update(purchase_ticket_reserve_id: tr.id)
      tr
    end

    before do
      create(:ticket_reserve, order: transfer_order, ticket: sold_ticket_2, transfer_from_user_id: transfer_from_user.id)
      create(:ticket_reserve, order: admin_transfer_order, ticket: sold_ticket_3)
      create(:ticket_reserve, order: order1, ticket: sold_ticket_4, seat_type_option: nil)
      create(:ticket_reserve, order: order2, ticket: sold_ticket_4, seat_type_option: nil)
      create(:ticket_reserve, order: order3, ticket: sold_ticket_4, seat_type_option: seat_type_option)
      create(:ticket_reserve, order: order51, ticket: sold_ticket_5, seat_type_option: nil)
      create(:ticket_reserve, order: order52, ticket: sold_ticket_5, seat_type_option: seat_type_option)
      tr = create(:ticket_reserve, order: order53, ticket: sold_ticket_5, seat_type_option: seat_type_option2, transfer_at: Time.zone.now, transfer_to_user_id: user)
      sold_ticket_5.update(purchase_ticket_reserve_id: tr.id)
      create(:ticket_reserve, order: order_irregular, ticket: sold_ticket_6, seat_type_option: seat_type_option2)
      create(:ticket, seat_type: seat_type_1, status: :available)
      create(:ticket, seat_type: seat_type_1, status: :sold, admission_disabled_at: Time.zone.now)
      create(:ticket, seat_type: seat_type_1, status: :sold, admission_disabled_at: Time.zone.now)
      create(:ticket, seat_type: seat_type_2, status: :sold, admission_disabled_at: Time.zone.now)
      create(:payment, order: purchase_order, payment_progress: :captured)
      create(:payment, order: order1, payment_progress: :requesting_payment)
      create(:payment, order: order2, payment_progress: :requesting_payment)
      create(:payment, order: order3, payment_progress: :captured)
      create(:payment, order: order51, payment_progress: :requesting_payment)
      create(:payment, order: order52, payment_progress: :requesting_payment)
      create(:payment, order: order53, payment_progress: :captured)
      create(:payment, order: order_irregular, payment_progress: :refunded)
      create(:payment, order: order78, payment_progress: :captured)
      create(:ticket_log, ticket_id: sold_ticket_1.id, request_status: :entered)
      create(:ticket_log, ticket_id: sold_ticket_5.id, request_status: :temporary_left)
    end

    it 'HTTPステータスが200であること' do
      ticket_export_csv
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json[0]['id']).to eq(sold_ticket_1.id)
      expect(json[0]['userId']).to eq(user.id)
      expect(json[0]['transferFromUserId']).to eq(sold_ticket1_ticket_reserve.transfer_from_user_id)
      expect(json[0]['eventDate']).to eq(sold_ticket_1.seat_sale.hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d'))
      expect(json[0]['dailyNo']).to eq(sold_ticket_1.seat_sale.hold_daily_schedule.daily_no)
      expect(json[0]['areaName']).to eq(sold_ticket_1.seat_area.master_seat_area.area_name)
      expect(json[0]['unitName']).to eq(nil)
      expect(json[0]['row']).to eq(sold_ticket_1.row)
      expect(json[0]['seatNumber']).to eq(sold_ticket_1.seat_number)
      expect(json[0]['optionTitle']).to eq(nil)
      expect(json[0]['couponTitle']).to eq(purchase_order.coupon.title)
      expect(json[0]['requestStatus']).to eq(sold_ticket_1.ticket_logs.last.request_status)
      expect(json[0]['couponId']).to eq(purchase_order.user_coupon.coupon_id)
      expect(json[0]['purchaseOrderId']).to eq(purchase_order.id)
    end

    it 'jsonはAdmin::CsvExportTicketSerializerの属性を持つハッシュであること' do
      ticket_export_csv
      json = JSON.parse(response.body)
      attributes = ::Admin::CsvExportTicketSerializer._attributes
      json.all? { |hash| expect(hash.keys).to match_array(attributes.map { |key| key.to_s.camelize(:lower) }) }
    end

    it 'ticket.statusがsoldで、admission_disabled_atがnilのもののみ返ること' do
      ticket_export_csv
      json = JSON.parse(response.body)
      expect(json.count).to be(8)
      expect(json.map { |hash| hash['id'] }).to match_array([sold_ticket_1.id, sold_ticket_2.id, sold_ticket_3.id, sold_ticket_4.id, sold_ticket_5.id, sold_ticket_6.id, sold_ticket_7.id, sold_ticket_8.id])
    end

    it '他ユーザーからの譲渡チケットは、transferFromUserIdに他ユーザーのユーザーIDが出力されること' do
      ticket_export_csv
      json = JSON.parse(response.body)
      expect(json[1]['transferFromUserId']).to eq(transfer_from_user.id)
    end

    it 'TicketReserveが複数ある場合もオプションが正しく出力されること' do
      ticket_export_csv
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json[3]['id']).to eq(sold_ticket_4.id)
      expect(json[3]['userId']).to eq(user.id)
      expect(json[3]['transferFromUserId']).to eq(sold_ticket4_ticket_reserve.transfer_from_user_id)
      expect(json[3]['eventDate']).to eq(sold_ticket_4.seat_sale.hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d'))
      expect(json[3]['dailyNo']).to eq(sold_ticket_4.seat_sale.hold_daily_schedule.daily_no)
      expect(json[3]['areaName']).to eq(sold_ticket_4.seat_area.master_seat_area.area_name)
      expect(json[3]['unitName']).to eq(nil)
      expect(json[3]['row']).to eq(sold_ticket_4.row)
      expect(json[3]['seatNumber']).to eq(sold_ticket_4.seat_number)
      expect(json[3]['couponTitle']).to eq(nil)
      expect(json[3]['optionTitle']).to eq(sold_ticket4_ticket_reserve.seat_type_option.title)
      expect(json[3]['requestStatus']).to eq(sold_ticket_4&.ticket_logs&.last&.request_status)
      expect(json[3]['couponId']).to eq(nil)
      expect(json[3]['purchaseOrderId']).to eq(sold_ticket4_ticket_reserve.order.id)
    end

    it '譲渡の場合、user_idが譲渡したユーザーになること、transfer_from_user_idが譲渡元のユーザーになること' do
      ticket_export_csv
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json[4]['id']).to eq(sold_ticket_5.id)
      expect(json[4]['userId']).to eq(user.id)
      expect(json[4]['transferFromUserId']).to eq(sold_ticket5_ticket_reserve.transfer_from_user_id)
      expect(json[4]['eventDate']).to eq(sold_ticket_5.seat_sale.hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d'))
      expect(json[4]['dailyNo']).to eq(sold_ticket_5.seat_sale.hold_daily_schedule.daily_no)
      expect(json[4]['areaName']).to eq(sold_ticket_5.seat_area.master_seat_area.area_name)
      expect(json[4]['unitName']).to eq(nil)
      expect(json[4]['row']).to eq(sold_ticket_5.row)
      expect(json[4]['seatNumber']).to eq(sold_ticket_5.seat_number)
      expect(json[4]['optionTitle']).to eq(sold_ticket5_ticket_reserve.seat_type_option.title)
      expect(json[4]['couponTitle']).to eq(nil)
      expect(json[4]['requestStatus']).to eq(sold_ticket_5.ticket_logs.last.request_status)
      expect(json[4]['couponId']).to eq(nil)
      expect(json[4]['purchaseOrderId']).to eq(order53.id)
    end

    it '２枚購入内１枚オプション設定、クーポン適用の売り上げとチケットが正しく出力されていること' do
      ticket_export_csv
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      index = json.find_index { |hash| hash['id'] == sold_ticket_8.id }
      expect(json[index]['id']).to eq(sold_ticket_8.id)
      expect(json[index]['userId']).to eq(user.id)
      expect(json[index]['transferFromUserId']).to eq(sold_ticket8_ticket_reserve.transfer_from_user_id)
      expect(json[index]['eventDate']).to eq(sold_ticket_8.seat_sale.hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d'))
      expect(json[index]['dailyNo']).to eq(sold_ticket_8.seat_sale.hold_daily_schedule.daily_no)
      expect(json[index]['areaName']).to eq(sold_ticket_8.seat_area.master_seat_area.area_name)
      expect(json[index]['unitName']).to eq(nil)
      expect(json[index]['row']).to eq(sold_ticket_8.row)
      expect(json[index]['seatNumber']).to eq(sold_ticket_8.seat_number)
      expect(json[index]['optionTitle']).to eq(sold_ticket8_ticket_reserve.seat_type_option.title)
      expect(json[index]['couponTitle']).to eq(nil)
      expect(json[index]['requestStatus']).to eq(sold_ticket_8&.ticket_logs&.last&.request_status)
      expect(json[index]['couponId']).to eq(nil)
      expect(json[index]['purchaseOrderId']).to eq(sold_ticket8_ticket_reserve.order.id)

      index = json.find_index { |hash| hash['id'] == sold_ticket_7.id }
      expect(json[index]['id']).to eq(sold_ticket_7.id)
      expect(json[index]['userId']).to eq(user.id)
      expect(json[index]['transferFromUserId']).to eq(sold_ticket7_ticket_reserve.transfer_from_user_id)
      expect(json[index]['eventDate']).to eq(sold_ticket_7.seat_sale.hold_daily_schedule.hold_daily.event_date.strftime('%Y-%m-%d'))
      expect(json[index]['dailyNo']).to eq(sold_ticket_7.seat_sale.hold_daily_schedule.daily_no)
      expect(json[index]['areaName']).to eq(sold_ticket_7.seat_area.master_seat_area.area_name)
      expect(json[index]['unitName']).to eq(nil)
      expect(json[index]['row']).to eq(sold_ticket_7.row)
      expect(json[index]['seatNumber']).to eq(sold_ticket_7.seat_number)
      expect(json[index]['optionTitle']).to eq(nil)
      expect(json[index]['couponTitle']).to eq(order78.coupon.title)
      expect(json[index]['requestStatus']).to eq(sold_ticket_7&.ticket_logs&.last&.request_status)
      expect(json[index]['couponId']).to eq(order78.user_coupon.coupon_id)
      expect(json[index]['purchaseOrderId']).to eq(sold_ticket7_ticket_reserve.order.id)
    end
  end
end
