# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admissions', type: :request do
  include AuthenticationHelper

  describe 'GET /verify', :sales_jwt_mock do
    subject(:verify) { get v1_admission_verify_url(ticket_id: ticket.qr_ticket_id), params: params, headers: access_token }

    let(:ticket) { create(:ticket, qr_ticket_id: AdmissionUuid.generate_uuid, status: ticket_status) }
    let(:user) { create(:user, qr_user_id: AdmissionUuid.generate_uuid) }
    let(:params) do
      {
        user_id: user.qr_user_id,
        device_id: '111'
      }
    end
    let(:ticket_status) { :available }

    context 'チケットが無い場合' do
      subject(:verify) { get v1_admission_verify_url(ticket_id: 'test'), params: params, headers: access_token }

      it 'TICKET_NOT_FOUNDが返ってくること' do
        verify
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_not_found') })
      end
    end

    context 'チケットが売り切れになっていない場合' do
      context 'チケットが空席の場合' do
        let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

        it 'TICKET_NOT_AVAILABLE_YETが返ってくること' do
          verify
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
          expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_not_available_yet') })
        end
      end

      context 'チケットが販売停止の場合' do
        let(:ticket_status) { :not_for_sale }
        let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

        it 'TICKET_NOT_AVAILABLE_YETが返ってくること' do
          verify
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
          expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_not_available_yet') })
        end
      end

      context 'チケットが決済処理中の場合' do
        let(:ticket_status) { :temporary_hold }
        let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

        it 'TICKET_NOT_AVAILABLE_YETが返ってくること' do
          verify
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
          expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_not_available_yet') })
        end
      end
    end

    context 'チケットの入場時間開始時間まえの場合' do
      let(:seat_sale) { create(:seat_sale, admission_available_at: Time.zone.now + 1.day, admission_close_at: Time.zone.now + 10.days) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, user: user, seat_type_id: seat_type.id, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

      it 'TICKET_NOT_AVAILABLE_YETが返ってくること' do
        verify
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(ticket.qr_ticket_id)
        expect(json['data']['user_id']).to eq(user.qr_user_id)
        expect(json['data']['status']).to eq(0)
        expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
        expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
        expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
        expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
        expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
        expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
        expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_not_available_yet') })
      end
    end

    context 'チケットの入場時間締め切り時間を過ぎている場合' do
      let(:seat_sale) { create(:seat_sale, :after_closing) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, seat_type_id: seat_type.id, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

      it 'TICKET_HAS_EXPIREDが返ってくること、log_type=2のチケットログが作成されていること' do
        expect { verify }.to change { TicketLog.where(ticket_id: ticket.id, log_type: 2).count }.by(1)
        expect(TicketLog.find_by(ticket_id: ticket.id).device_id).to eq('111')
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(ticket.qr_ticket_id)
        expect(json['data']['user_id']).to eq(user.qr_user_id)
        expect(json['data']['status']).to eq(0)
        expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
        expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
        expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
        expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
        expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
        expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
        expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_has_expired') })
      end
    end

    context 'ユーザーが正しく無い場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:another_user) { create(:user) }
      let(:ticket) { create(:ticket, seat_type: seat_type, user: another_user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

      it 'TICKET_VALIDATE_FAILEDが返ってくること' do
        verify
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(ticket.qr_ticket_id)
        expect(json['data']['user_id']).to eq(user.qr_user_id)
        expect(json['data']['status']).to eq(0)
        expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
        expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
        expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
        expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
        expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
        expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
        expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_validate_failed') })
      end
    end

    context '譲渡中の場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, seat_type: seat_type, user: user, status: :sold, transfer_uuid: 'xxxx', qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

      it 'TICKET_VALIDATE_FAILEDが返ってくること' do
        verify
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(ticket.qr_ticket_id)
        expect(json['data']['user_id']).to eq(user.qr_user_id)
        expect(json['data']['status']).to eq(0)
        expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
        expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
        expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
        expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
        expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
        expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
        expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_validate_failed') })
      end
    end

    context '成功の場合' do
      let(:user) { create(:user, :user_with_order) }
      let(:ticket) { user.tickets.first }
      let(:hold_daily) { ticket.seat_type.seat_sale.hold_daily }
      let(:seat_type_option) { ticket.ticket_reserves.first.seat_type_option }

      before do
        user
        create(:profile, user: user, auth_code: sixgram_access_token)
      end

      it 'チケットログがない場合（譲渡のデータ）' do
        verify
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(ticket.qr_ticket_id)
        expect(json['data']['user_id']).to eq(user.qr_user_id)
        expect(json['data']['status']).to eq(0)
        expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
        expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
        expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
        expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
        expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
        expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option.title)
      end

      it 'チケットの状態が入場前の場合' do
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :before_enter)
        verify
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']['status']).to eq(0)
      end

      it 'チケットの状態が入場前から入場に更新された場合' do
        create(:profile, user: user)
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :before_enter)
        # 入場に更新
        post v1_admission_update_log_url(ticket_id: ticket.qr_ticket_id), params: { request_status: 1, result: 1 }, headers: access_token

        verify
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']['status']).to eq(1)
      end

      it 'チケットの状態が入場前から入場に更新APIが飛んできたが、顔認証で失敗していた場合' do
        create(:profile, user: user)
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :before_enter)
        # 入場に更新（顔認証で失敗していたため、resultが0）
        post v1_admission_update_log_url(ticket_id: ticket.qr_ticket_id), params: { request_status: 1, result: 0 }, headers: access_token

        verify
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']['status']).to eq(0)
      end
    end

    context 'ユーザーがいない場合' do
      let(:params) { { user_id: 9999 } }
      let(:ticket) { create(:user, :user_with_order).tickets.first }

      it 'TICKET_VALIDATE_FAILEDが返ってくること' do
        verify
        expect(response.body).to include I18n.t('admission.ticket_validate_failed')
      end
    end

    context 'headerにtokenがない場合' do
      it '認証エラーが返ること' do
        get v1_admission_verify_url(ticket_id: ticket.id), params: params
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['message']).to eq 'token invalid'
      end
    end

    context 'チケット無効化されている場合' do
      let(:user) { create(:user, :user_with_order) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, seat_type: seat_type, user: user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid, admission_disabled_at: Time.zone.now) }
      let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

      it 'TICKET_HAS_BANNEDが返ってくること' do
        verify
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(ticket.qr_ticket_id)
        expect(json['data']['user_id']).to eq(user.qr_user_id)
        expect(json['data']['status']).to eq(0)
        expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
        expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
        expect(json['data']['ticket']['hold_datetime']).to eq(ticket.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
        expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
        expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
        expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
        expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_has_banned') })
      end
    end

    # TODO: NGユーザーチェックスキップ
    # context 'NGユーザーの場合' do
    #   let(:sales_jwt_mock_user_sixgram_id) { '09000010002' }
    #   let(:user) { create(:user, :user_with_order) }
    #   let(:seat_sale) { create(:seat_sale, :in_admission_term) }
    #   let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    #   let(:ticket) { create(:ticket, seat_type: seat_type, user: user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid) }
    #   let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

    #   it 'TICKET_HAS_BANNEDが返ってくること' do
    #     create(:profile, user: user, auth_code: sixgram_access_token)
    #     verify
    #     json = JSON.parse(response.body)
    #     expect(json['data']['id']).to eq(ticket.qr_ticket_id)
    #     expect(json['data']['user_id']).to eq(user.qr_user_id)
    #     expect(json['data']['status']).to eq(0)
    #     expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
    #     expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
    #     expect(json['data']['ticket']['hold_datetime']).to eq(ticket.seat_type.seat_sale.admission_available_at.strftime('%Y-%m-%d %H:%M:%S'))
    #     expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
    #     expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
    #     expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
    #     expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_has_banned') })
    #   end
    # end

    # TODO: NGユーザーチェックスキップ
    # context 'ユーザー認証トークンが有効期限切れで失効していて、ng_user_checkがfalseの場合' do
    #   let(:sales_jwt_mock_user_sixgram_id) { '09000020004' }
    #   let(:user) { create(:user, :user_with_order) }
    #   let(:seat_sale) { create(:seat_sale, :in_admission_term) }
    #   let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    #   let(:ticket) { create(:ticket, seat_type: seat_type, user: user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid) }
    #   let(:seat_type_option) { ticket.ticket_reserves.first&.seat_type_option }

    #   it 'TICKET_HAS_BANNEDが返ってくること' do
    #     create(:profile, user: user, auth_code: sixgram_access_token, ng_user_check: false)
    #     verify
    #     json = JSON.parse(response.body)
    #     expect(json['data']['id']).to eq(ticket.qr_ticket_id)
    #     expect(json['data']['user_id']).to eq(user.qr_user_id)
    #     expect(json['data']['status']).to eq(0)
    #     expect(json['data']['created_at']).to eq(ticket.created_at.iso8601)
    #     expect(json['data']['updated_at']).to eq(ticket.updated_at.iso8601)
    #     expect(json['data']['ticket']['hold_datetime']).to eq(ticket.seat_type.seat_sale.admission_available_at.strftime('%Y-%m-%d %H:%M:%S'))
    #     expect(json['data']['ticket']['seat_type_name']).to eq(ticket.coordinate_seat_type_name)
    #     expect(json['data']['ticket']['seat_number']).to eq(ticket.coordinate_seat_number)
    #     expect(json['data']['ticket']['seat_type_option']).to eq(seat_type_option&.title)
    #     expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_has_banned') })
    #   end
    # end

    context 'ユーザー認証トークンが有効期限切れで失効していて、ng_user_checkがtrueの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000020004' }
      let(:user) { create(:user, :user_with_order) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, seat_type: seat_type, user: user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid) }

      it '成功すること（チケットログがある場合）' do
        create(:profile, user: user, auth_code: sixgram_access_token, ng_user_check: true)
        create(:ticket_log, ticket: ticket, result: 'true', result_status: :before_enter)
        verify
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']['status']).to eq(0)
      end
    end

    context '管理画面から譲渡の場合' do
      let(:user) { create(:user, :with_profile) }
      let(:seat_type_option) { create(:seat_type_option) }
      let!(:ticket_reserve_ticket1) { create(:ticket_reserve, order: order, ticket: ticket1, seat_type_option: nil) }
      let!(:ticket_reserve_ticket2) { create(:ticket_reserve, order: order, ticket: ticket2, seat_type_option: seat_type_option) }
      let(:ticket1) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:ticket2) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:order) { create(:order, order_type: :admin_transfer, user: user) }
      let(:params) do
        {
          user_id: user.qr_user_id,
          device_id: '111'
        }
      end

      context 'オプション指定のないチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket1.qr_ticket_id), params: params, headers: access_token }

        it '成功し、該当のチケット情報が返されること' do
          verify
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket1.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket1.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket1.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket1.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket1.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket1.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(ticket_reserve_ticket1&.seat_type_option&.title)
        end
      end

      context 'オプション指定しているチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket2.qr_ticket_id), params: params, headers: access_token }

        it '成功し、該当のチケット情報が返されること' do
          verify
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket2.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket2.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket2.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket2.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket2.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket2.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(ticket_reserve_ticket2&.seat_type_option&.title)
        end
      end
    end

    context 'TicketReserveが３つある場合（requesting_paymentが２つ、capturedが１つあるケース）' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket1, seat_type_option: nil)
        create(:ticket_reserve, order: order1, ticket: ticket2, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket1, seat_type_option: seat_type_option)
        create(:ticket_reserve, order: order2, ticket: ticket2, seat_type_option: nil)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :requesting_payment)
        create(:payment, order: order3, payment_progress: :captured)
      end

      let(:user) { create(:user, :with_profile) }
      let(:seat_type_option) { create(:seat_type_option) }
      let!(:ticket_reserve_ticket1) { create(:ticket_reserve, order: order3, ticket: ticket1, seat_type_option: nil) }
      let!(:ticket_reserve_ticket2) { create(:ticket_reserve, order: order3, ticket: ticket2, seat_type_option: seat_type_option) }
      let(:ticket1) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:ticket2) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:order1) { create(:order, order_type: :purchase, user: user) }
      let(:order2) { create(:order, order_type: :purchase, user: user) }
      let(:order3) { create(:order, order_type: :purchase, user: user) }
      let(:params) do
        {
          user_id: user.qr_user_id,
          device_id: '111'
        }
      end

      context 'オプション指定のないチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket1.qr_ticket_id), params: params, headers: access_token }

        it '成功し、該当のチケット情報が返されること' do
          verify
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket1.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket1.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket1.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket1.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket1.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket1.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(ticket_reserve_ticket1&.seat_type_option&.title)
        end
      end

      context 'オプション指定しているチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket2.qr_ticket_id), params: params, headers: access_token }

        it '成功し、該当のチケット情報が返されること' do
          verify
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket2.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket2.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket2.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket2.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket2.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket2.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(ticket_reserve_ticket2&.seat_type_option&.title)
        end
      end
    end

    context 'TicketReserveに譲渡がある場合' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket1, seat_type_option: nil)
        create(:ticket_reserve, order: order1, ticket: ticket2, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket2, seat_type_option: seat_type_option, transfer_at: Time.zone.now)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :captured)
      end

      let(:user) { create(:user, :with_profile) }
      let(:user2) { create(:user, :with_profile) }
      let(:seat_type_option) { create(:seat_type_option) }
      let!(:ticket_reserve_ticket1) { create(:ticket_reserve, order: order2, ticket: ticket1, seat_type_option: seat_type_option) }
      let!(:ticket_reserve_ticket2) { create(:ticket_reserve, order: order3, ticket: ticket2, seat_type_option: seat_type_option) }
      let(:ticket1) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:ticket2) { create(:ticket, :ticket_with_admission_term, status: :sold, user: user2, qr_ticket_id: AdmissionUuid.generate_uuid) }
      let(:order1) { create(:order, order_type: :purchase, user: user) }
      let(:order2) { create(:order, order_type: :purchase, user: user) }
      let(:order3) { create(:order, order_type: :transfer, user: user2) }
      let(:params) do
        {
          user_id: user.qr_user_id,
          device_id: '111'
        }
      end

      context '譲渡していないチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket1.qr_ticket_id), params: params, headers: access_token }

        it '成功し、該当のチケット情報が返されること' do
          verify
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket1.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket1.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket1.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket1.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket1.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket1.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(ticket_reserve_ticket1&.seat_type_option&.title)
        end
      end

      context '譲渡しているチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket2.qr_ticket_id), params: params, headers: access_token }

        it 'エラーが返されること' do
          verify
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket2.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket2.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket2.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket2.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket2.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket2.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(nil)
          expect(json['errors'][0]).to eq({ 'message' => I18n.t('admission.ticket_validate_failed') })
        end
      end

      context '譲渡受け取ったuser2でチケットを指定した場合' do
        subject(:verify) { get v1_admission_verify_url(ticket_id: ticket2.qr_ticket_id), params: params, headers: access_token }

        let(:params) do
          {
            user_id: user2.qr_user_id,
            device_id: '111'
          }
        end

        it '成功し、該当のチケット情報が返されること' do
          verify
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['data']['id']).to eq(ticket2.qr_ticket_id)
          expect(json['data']['user_id']).to eq(user2.qr_user_id)
          expect(json['data']['status']).to eq(0)
          expect(json['data']['created_at']).to eq(ticket2.created_at.iso8601)
          expect(json['data']['updated_at']).to eq(ticket2.updated_at.iso8601)
          expect(json['data']['ticket']['hold_datetime']).to eq(ticket2.hold_daily.event_date.strftime("%Y-%m-%d #{ticket.hold_daily_schedule.opening_display}"))
          expect(json['data']['ticket']['seat_type_name']).to eq(ticket2.coordinate_seat_type_name)
          expect(json['data']['ticket']['seat_number']).to eq(ticket2.coordinate_seat_number)
          expect(json['data']['ticket']['seat_type_option']).to eq(ticket_reserve_ticket2&.seat_type_option&.title)
        end
      end
    end
  end

  describe 'POST /update_log' do
    subject(:update_log) { post v1_admission_update_log_url(ticket_id: ticket.qr_ticket_id), params: params, headers: access_token }

    let(:ticket) { create(:ticket, user: create(:profile).user, qr_ticket_id: AdmissionUuid.generate_uuid) }
    let(:params) { { request_status: 1, result: 1, device_id: '111' } }
    let(:invalid_params1) { { request_status: 10, result: 1 } }
    let(:invalid_params2) { { request_status: 1 } }

    context 'logがない場合' do
      it 'logが作成されること' do
        update_log
        expect(response).to have_http_status(:success)
      end
    end

    context 'logがある場合' do
      it '最新のlogのstatusを継承' do
        create(:ticket_log, ticket: ticket, result: 1)
        update_log
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(true)
        expect(ticket.ticket_logs.first.result_status).to eq(ticket.ticket_logs.last.status)
        expect(ticket.ticket_logs.last.device_id).to eq('111')
      end
    end

    context 'request_statusが1の場合' do
      it 'visitor_profileが作成されること' do
        expect { update_log }.to change(VisitorProfile, :count).by(1)
        expect(ticket.user.sixgram_id).to eq(VisitorProfile.first.sixgram_id)
        expect(ticket.user.profile.family_name).to eq(VisitorProfile.first.family_name)
        expect(ticket.user.profile.given_name).to eq(VisitorProfile.first.given_name)
        expect(ticket.user.profile.family_name_kana).to eq(VisitorProfile.first.family_name_kana)
        expect(ticket.user.profile.given_name_kana).to eq(VisitorProfile.first.given_name_kana)
        expect(ticket.user.profile.birthday).to eq(VisitorProfile.first.birthday)
        expect(ticket.user.profile.zip_code).to eq(VisitorProfile.first.zip_code)
        expect(ticket.user.profile.prefecture).to eq(VisitorProfile.first.prefecture)
        expect(ticket.user.profile.city).to eq(VisitorProfile.first.city)
        expect(ticket.user.profile.address_line).to eq(VisitorProfile.first.address_line)
        expect(ticket.user.profile.email).to eq(VisitorProfile.first.email)
      end
    end

    context 'request_statusが１ではない場合' do
      let(:params) { { request_status: 2, result: 1 } }

      it 'visitor_profileが作成されないこと' do
        expect { update_log }.to change(VisitorProfile, :count).by(0)
      end
    end

    context 'パラメタが不正な場合' do
      it 'パラメータに不正がある場合' do
        post v1_admission_update_log_url(ticket_id: ticket.qr_ticket_id), params: invalid_params1, headers: access_token
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors'].first['message']).to eq('THE_VALUE_YOU_HAVE_ENTERED_IS_INVALID')
        expect(json['errors'].first['field']).to eq('request_status')
      end

      it '必須のパラメータがない場合' do
        post v1_admission_update_log_url(ticket_id: ticket.qr_ticket_id), params: invalid_params2, headers: access_token
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors'].first['message']).to eq('THE_REQUEST_TICKET_ID_FIELD_IS_REQUIRED')
        expect(json['errors'].first['field']).to eq('result')
      end
    end
  end

  describe 'DELETE /update_clean_log' do
    subject(:update_clean_log) { delete v1_admission_update_clean_log_url(ticket_id: ticket.qr_ticket_id), params: { device_id: '111' }, headers: access_token }

    let(:ticket) { create(:ticket, qr_ticket_id: 1) }

    context '成功の場合' do
      it 'cleanのログが作成されること' do
        create(:ticket_log, ticket: ticket, result: 1, status: :entered)
        update_clean_log
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(true)
        expect(ticket.ticket_logs.last.device_id).to eq('111')
      end
    end

    context '失敗の場合' do
      it 'ticketがない場合' do
        delete v1_admission_update_clean_log_url(ticket_id: 9999), headers: access_token
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include I18n.t('admission.ticket_not_found')
      end

      it 'チケットステータスをBEFORE_ENTERの場合' do
        create(:ticket_log, ticket: ticket, result: 'true', status: :before_enter)
        update_clean_log
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include I18n.t('admission.ticket_cannot_clean')
      end

      it 'ログがない場合' do
        update_clean_log
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include I18n.t('admission.ticket_cannot_clean')
      end

      context '顔認証アプリ上のチケット情報がない場合' do
        let(:ticket) { create(:ticket, qr_ticket_id: 999) }

        it '失敗すること' do
          create(:ticket_log, ticket: ticket, result: 1, status: :entered)
          update_clean_log
          expect(response).to have_http_status(:not_found)
          expect(response.body).to include I18n.t('admission.ticket_not_found')
        end
      end

      context '顔認証アプリの削除が失敗した場合' do
        let(:ticket) { create(:ticket, qr_ticket_id: 2) }

        it '失敗すること' do
          create(:ticket_log, ticket: ticket, result: 1, status: :entered)
          update_clean_log
          expect(response).to have_http_status(:bad_request)
          expect(response.body).to include I18n.t('admission.ticket_cannot_clean')
        end
      end
    end
  end
end
