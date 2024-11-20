# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tickets', type: :request do
  describe 'PUT ticket_reserves/:id/transfer', :sales_logged_in do
    subject(:ticket_transfer) { put sales_transfer_ticket_url(ticket_reserve.id, format: :json) }

    let(:ticket) { create(:ticket, :sold, seat_type: seat_type, user_id: sales_logged_in_user.id) }
    let(:order) { create(:order, order_at: Time.zone.now, order_type: :purchase, seat_sale: seat_sale, user: sales_logged_in_user) }
    let(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }

    context 'ログインユーザーが所持しているチケット' do
      it 'HTTPステータスが200であること' do
        ticket_transfer
        expect(response).to have_http_status(:ok)
      end

      it '対象のticketのtransfer_uuidが埋まること' do
        expect { ticket_transfer }.to change { Ticket.find(ticket.id).transfer_uuid.present? }.from(false).to(true)
      end
    end

    context '譲渡済みだった場合' do
      before do
        put sales_transfer_ticket_url(ticket_reserve.id)
      end

      it 'HTTPステータスが400であること' do
        ticket_transfer
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'ログインユーザーが所持していないチケット' do
      let(:ticket) { create(:ticket) }

      it 'HTTPステータスが400であること' do
        ticket_transfer

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'transfer_ticket_error', 'detail' => 'チケット所持者ではありません', 'status' => 400 })
      end

      it '対象のticketのtransfer_uuidに変化がないこと' do
        expect { ticket_transfer }.not_to change(ticket, :transfer_uuid)
      end
    end

    context 'チケット予約が存在しない場合' do
      it 'HTTPステータスが400であること' do
        put sales_transfer_ticket_url(1, format: :json)

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'transfer_ticket_error', 'detail' => '該当のチケット予約がありません', 'status' => 400 })
      end
    end

    # TODO: NGユーザーチェックスキップ
    # context 'NGユーザーだった場合' do
    #   let(:sales_logged_in_user_sixgram_id) { '09000010002' }

    #   it '403エラーが発生する前にログインできない' do
    #     ticket_transfer
    #     expect(response).to have_http_status(:unauthorized)
    #     body = JSON.parse(response.body)
    #     expect(body['code']).to eq('login_required')
    #     expect(session[:user_auth_token].present?).to be false
    #   end
    # end
  end

  describe 'GET tickets/:transfer_uuid/receive' do
    subject(:get_receive_ticket) { get sales_receive_ticket_url(ticket.transfer_uuid, format: :json) }

    let(:ticket) { create(:ticket, :sold) }

    context '譲渡されたチケット確認' do
      it 'HTTPステータスが200であること' do
        ticket.sold_ticket_uuid_generate!
        get_receive_ticket
        expect(response).to have_http_status(:ok)
      end

      it 'HTTPステータスが404であること' do
        ticket.sold_ticket_uuid_generate!
        get sales_receive_ticket_url(9999, ticket.transfer_uuid, format: :json)
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'not_found', 'detail' => '指定されたデータまたはページが存在しません', 'status' => 404 })
      end
    end
  end

  describe 'POST tickets/:transfer_uuid/receive', :sales_logged_in do
    subject(:sales_receive_ticket) { post sales_receive_ticket_url(receive_ticket.transfer_uuid, format: :json) }

    before do
      tr = create(
        :ticket_reserve,
        ticket_id: receive_ticket.id, seat_type_option_id: seat_type_option.id,
        order_id: order.id, transfer_at: nil, transfer_from_user_id: nil, transfer_to_user_id: nil
      )
      receive_ticket.update(current_ticket_reserve_id: tr.id)
      create(:payment, order: order, payment_progress: :captured)
    end

    let(:user) { create(:user) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_type_option) { create(:seat_type_option, seat_type_id: seat_type.id) }
    let(:order) { user.orders.create(user_id: user, order_at: Time.zone.now, order_type: 0, total_price: 10_000, seat_sale: seat_sale) }
    let(:receive_ticket) { create(:ticket, :sold, seat_type: seat_type, user_id: user.id, transfer_uuid: 'uuid') }

    context '譲渡受け取る場合' do
      it 'HTTPステータスが200であること' do
        sales_receive_ticket
        receive_ticket.reload
        expect(response).to have_http_status(:ok)
      end

      it '確認メールが送信されること' do
        profile = create(:profile, user: user)
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { sales_receive_ticket } }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.map(&:to)).to include [profile.email]
        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】チケット譲渡が完了しました'
      end

      context '譲渡元ユーザーが退会済みの場合' do
        before do
          user.touch(:deleted_at)
          create(:profile, user: user)
        end

        it '確認メールが送信されないこと' do
          expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { sales_receive_ticket } }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      # TODO: NGユーザーチェックスキップ
      # context 'NGユーザーだった場合' do
      #   let(:sales_logged_in_user_sixgram_id) { '09000010002' }

      #   it '403エラーが発生する前にログインできない' do
      #     receive
      #     expect(response).to have_http_status(:unauthorized)
      #     body = JSON.parse(response.body)
      #     expect(body['code']).to eq('login_required')
      #     expect(session[:user_auth_token].present?).to be false
      #   end
      # end
    end

    context 'すでに入場している場合' do
      before do
        create(:ticket_log, ticket: receive_ticket, result_status: :entered)
      end

      it 'HTTPステータスが400であること' do
        sales_receive_ticket
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('入場済みのチケットは譲渡できません')
      end
    end

    context '未入場の場合' do
      before do
        create(:ticket_log, ticket: receive_ticket, result_status: :before_enter)
      end

      it '正常終了すること' do
        sales_receive_ticket
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST tickets/:transfer_uuid/receive_admin_ticket', :sales_logged_in, :admin_logged_in do
    subject(:receive_admin_ticket) { post sales_receive_admin_ticket_url(ticket.transfer_uuid) }

    let(:ticket) { create(:ticket, seat_type: seat_type) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :available, :in_admission_term) }

    before do
      put admin_ticket_stop_selling_url, params: { ticket_ids: [ticket.id] }
      put admin_ticket_transfer_url, params: { ticket_ids: [ticket.id] }
      ticket.reload
    end

    it '管理譲渡チケットを受け取ることができること' do
      receive_admin_ticket
      expect(response).to have_http_status(:ok)
    end

    # context 'NGユーザーだった場合' do
    # 譲渡受け取りで403エラーが実装されているが、
    # NGユーザーでセッションクリアされるときにtransfer_uuidも消えてしまい、譲渡できなくなってしまう。
    # let(:sales_logged_in_user_sixgram_id) { '09000010002' }

    # it '403エラーが発生する前にログインできない' do
    #   receive_admin_ticket
    #   expect(response).to have_http_status(:unauthorized)
    #   body = JSON.parse(response.body)
    #   expect(body['code']).to eq('login_required')
    # end
    # end
  end

  describe 'PUT ticket_reserves/:id/transfer_cancel', :sales_logged_in do
    subject(:transfer_cancel) { put sales_transfer_cancel_url(ticket_reserve.id) }

    let(:order) { create(:order, order_at: Time.zone.now, order_type: :purchase, seat_sale: seat_sale, user: sales_logged_in_user) }
    let(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }

    context 'チケットの所持者がログインユーザーである場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type, user_id: sales_logged_in_user.id, transfer_uuid: 'abcdefghij1234567', status: :sold) }

      it 'transfer_uuidがnilになること' do
        expect { transfer_cancel }.to change { Ticket.find(ticket.id).transfer_uuid.present? }.from(true).to(false)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'チケットの所持者がログインユーザーでない場合' do
      let(:user_2) { create(:user) }
      let(:ticket) { create(:ticket, seat_type: seat_type, user_id: user_2.id, transfer_uuid: 'abcdefghij1234567', status: :sold) }

      it 'TransferTicketErrorが返り、transfer_uuidが変化しないこと' do
        transfer_cancel

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'transfer_ticket_error', 'detail' => 'チケット所持者ではありません', 'status' => 400 })
        expect(Ticket.find(ticket.id).transfer_uuid).to eq ticket.transfer_uuid
      end
    end

    context 'チケット予約が存在しない場合' do
      it 'HTTPステータスが400であること' do
        put sales_transfer_cancel_url(1, format: :json)

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'transfer_ticket_error', 'detail' => '該当のチケット予約がありません', 'status' => 400 })
      end
    end
  end
end
