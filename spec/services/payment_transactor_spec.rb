# frozen_string_literal: true

require 'rails_helper'

describe PaymentTransactor, type: :model do
  describe '#request', :sales_jwt_mock do
    subject(:charge_request) do
      described_class.request(user, sixgram_access_token, 'https://example.com')
    end

    context 'リクエストが成功した場合' do
      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:user) { create(:user, :with_profile) }
      let(:cart) { Cart.new(user) }

      let(:seat_sale) { create(:seat_sale, :available) }
      let(:template_seat_type1) { create(:template_seat_type, price: 1000) }
      let(:template_seat_type2) { create(:template_seat_type, price: 2000) }
      let(:seat_type1) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type1) }
      let(:seat_type2) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type2) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket2) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket3) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
      let(:ticket4) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }

      let(:seat_type_option1) { create(:seat_type_option, seat_type: seat_type1) }
      let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type2) }

      let(:template_coupon) { create(:template_coupon, rate: 10) }
      let(:user_coupon) { create(:user_coupon, coupon: create(:coupon, :available_coupon, template_coupon: template_coupon), user: user) }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option2.id },
          { ticket_id: ticket4.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'TicketReserve、Order、Paymentレコードが作成されること' do
        charge_request
        expect(Order.where(user: user).count).to eq(1)
        orders.each do |o|
          ticket_reserve = TicketReserve.find_by(ticket_id: o[:ticket_id], seat_type_option_id: o[:option_id])
          expect(ticket_reserve.present?).to be true
        end

        user_order = Order.where(user: user).first
        expect(user_order.option_discount).to eq(2)
      end

      it 'cartとticketの確保期限が延長されていること' do
        old_ticket_ttl = cart.tickets.first.temporary_owner_id.ttl
        old_cart_ttl = cart.ticket_orders.ttl
        sleep(2)
        charge_request
        expect(cart.tickets.first.temporary_owner_id.ttl).to be >= old_ticket_ttl
        expect(cart.ticket_orders.ttl).to be >= old_cart_ttl
      end

      context 'クーポンを選択した場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil }
          ]
        end
        let(:coupon_id) { user_coupon.coupon.id }
        let(:campaign_code) { nil }

        it 'orderとクーポンが紐づいていること' do
          charge_request

          user_order = Order.where(user: user).first
          expect(user_order.user_coupon.id).to eq(user_coupon.id)
          expect(user_order.coupon_discount).to eq(600)
        end
      end

      context 'キャンペーンコードを使用した場合' do
        let(:campaign) { create(:campaign, approved_at: Time.zone.now.yesterday) }

        let(:campaign_code) { campaign.code }

        it 'orderとキャンペーンが紐づいていること' do
          charge_request

          user_order = Order.where(user: user).first
          expect(user_order.campaign_usage).to eq(CampaignUsage.first)
          expect(user_order.campaign_discount).to eq(300)
        end
      end

      context '不正なトークンの場合' do
        let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

        it 'エラーが発生すること' do
          expect { charge_request }.to raise_error(InvalidSixgramUserAuthError)
        end
      end

      context 'オーダーが空の場合' do
        before do
          cart.clear_hold_tickets
        end

        it 'エラーが返却されること' do
          expect(charge_request[:error]).to eq('no_order')
        end
      end

      context '座席の所有権がない場合' do
        before do
          ticket1.ticket_release(user.id)
          ticket2.try_reserve(user2.id)
        end

        let(:user2) { create(:user) }

        it 'エラーが返却されること' do
          expect(charge_request[:error]).to eq('ownership_error')
        end
      end

      context '販売期間を超えた場合' do
        before do
          seat_sale.update!(sales_start_at: Time.zone.now - 2.hours, sales_end_at: Time.zone.now - 1.hour)
        end

        it 'エラーが返却されること' do
          expect(charge_request[:error]).to eq('sale_term_outside')
        end
      end
    end
  end

  describe 'request_completed', :sales_jwt_mock do
    subject(:request_completed) do
      cart.replace_tickets(orders, coupon_id, campaign_code)
      described_class.request_completed(user, charge_id)
    end

    before do
      create(:ticket_reserve, order: order, ticket: ticket1, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket2, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket3, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket4, seat_type_option: nil)
    end

    let(:user) { create(:user, :with_profile) }

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type) { create(:template_seat_type, price: 1000) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket3) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket4) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

    let(:order) { create(:order, total_price: total_price) }
    let!(:payment) { create(:payment, order: order, charge_id: charge_id, payment_progress: :requesting_payment) }
    let(:total_price) { 6000 }
    let(:charge_id) { 'charge_id' }

    let(:cart) { Cart.new(user) }
    let(:orders) do
      [
        { ticket_id: ticket1.id, option_id: nil },
        { ticket_id: ticket2.id, option_id: nil },
        { ticket_id: ticket3.id, option_id: nil },
        { ticket_id: ticket4.id, option_id: nil }
      ]
    end
    let(:coupon_id) { nil }
    let(:campaign_code) { nil }

    context '支払確定が成功した場合' do
      it 'Ticketがユーザーに紐づくこと' do
        request_completed
        expect(payment.reload.payment_progress).to eq('captured')
        expect(user.tickets).to eq([ticket1, ticket2, ticket3, ticket4])
        expect(user.tickets.all?(&:sold?)).to be true
      end

      it '決済後にメールが通知されること' do
        perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
          expect { request_completed }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        expect(ActionMailer::Base.deliveries.map(&:to)).to include [user.profile.email]
      end

      it 'paymentのcaptured_atが登録されていること' do
        request_completed
        expect(payment.reload.captured_at).not_to eq(nil)
      end

      it 'Ticketが持つ購入時と有効なTicketReserveのIDが更新されること' do
        request_completed
        payment.order.ticket_reserves.each do |tr|
          ticket = tr.ticket
          expect(ticket.purchase_ticket_reserve_id).to eq(tr.id)
          expect(ticket.current_ticket_reserve_id).to eq(tr.id)
        end
      end
    end

    # already_captureはエラーを返さずに購入完了画面へ戻すようにする ※テスト上ステータス等は購入完了しません
    context '支払確定中にエラーが発生した場合' do
      context 'already_captured: 確定済のChargeが指定された場合' do
        let(:charge_id) { '412111' }

        it 'エラーが発生しないこと' do
          result = request_completed
          expect(result).to eq({ info: 'already_captured' })
        end

        it 'チケットのステータスがtemporary_holdであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.temporary_hold? }).to be true
        end

        it 'チケットのuser_idが紐づいていること' do
          request_completed
          expect(user.tickets).to eq([ticket1, ticket2, ticket3, ticket4])
        end

        it '返金日時に日付が入っていないこと' do
          request_completed
          expect(order.reload.returned_at).to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          request_completed
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていないこと' do
          request_completed
          expect(payment.reload.refunded_at).to eq(nil)
        end
      end

      context 'already_refunded: 返金済のChargeが指定された場合' do
        let(:charge_id) { '412112' }

        it 'エラーが発生すること' do
          result = request_completed
          expect(payment.reload.failed_capture?).to be true
          expect(result[:error]).to eq('already_refunded')
        end

        it 'チケットのステータスがavailableであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.available? }).to be true
        end

        it 'チケットのuser_idがnilであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.user_id.nil? }).to be true
        end

        it '返金日時に日付が入っていること' do
          request_completed
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          request_completed
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          request_completed
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'disputed: チャージバック済のChargeが指定された場合' do
        let(:charge_id) { '412113' }

        it 'エラーが発生すること' do
          result = request_completed
          expect(payment.reload.failed_capture?).to be true
          expect(result[:error]).to eq('disputed')
        end

        it 'チケットのステータスがavailableであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.available? }).to be true
        end

        it 'チケットのuser_idがnilであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.user_id.nil? }).to be true
        end

        it '返金日時に日付が入っていること' do
          request_completed
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          request_completed
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          request_completed
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'expired_for_capture: 決済確定期限を超えたChargeが指定された' do
        let(:charge_id) { '412114' }

        it 'エラーが発生すること' do
          result = request_completed
          expect(payment.reload.failed_capture?).to be true
          expect(result[:error]).to eq('expired_for_capture')
        end

        it 'チケットのステータスがavailableであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.available? }).to be true
        end

        it 'チケットのuser_idがnilであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.user_id.nil? }).to be true
        end

        it '返金日時に日付が入っていること' do
          request_completed
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          request_completed
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          request_completed
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'card_declined: 何らかの理由で決済に失敗した場合' do
        let(:charge_id) { '412115' }

        it 'エラーが発生すること' do
          result = request_completed
          expect(payment.reload.failed_capture?).to be true
          expect(result[:error]).to eq('card_declined')
        end

        it 'チケットのステータスがavailableであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.available? }).to be true
        end

        it 'チケットのuser_idがnilであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.user_id.nil? }).to be true
        end

        it '返金日時に日付が入っていること' do
          request_completed
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          request_completed
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          request_completed
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'resource_not_found: 存在しないChargeが指定された場合' do
        let(:charge_id) { '412116' }

        it 'エラーが発生すること' do
          result = request_completed
          expect(payment.reload.failed_capture?).to be true
          expect(result[:error]).to eq('resource_not_found')
        end

        it 'チケットのステータスがavailableであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.available? }).to be true
        end

        it 'チケットのuser_idがnilであること' do
          request_completed
          tickets = [ticket1, ticket2, ticket3, ticket4]
          expect(tickets.all? { |t| t.reload.user_id.nil? }).to be true
        end

        it '返金日時に日付が入っていること' do
          request_completed
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          request_completed
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          request_completed
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end
    end

    context 'captured:false 支払確定が失敗していた場合' do
      let(:charge_id) { '212114' }

      it 'エラーが発生すること' do
        result = request_completed
        expect(payment.reload.failed_capture?).to be true
        expect(result[:error]).to eq('failed_capture')
      end

      it 'チケットのステータスがavailableであること' do
        request_completed
        tickets = [ticket1, ticket2, ticket3, ticket4]
        expect(tickets.all? { |t| t.reload.available? }).to be true
      end

      it 'チケットのuser_idがnilであること' do
        request_completed
        tickets = [ticket1, ticket2, ticket3, ticket4]
        expect(tickets.all? { |t| t.reload.user_id.nil? }).to be true
      end

      it '返金日時に日付が入っていること' do
        request_completed
        expect(order.reload.returned_at).not_to eq(nil)
      end

      it 'paymentのcaptured_atが登録されていないこと' do
        request_completed
        expect(payment.reload.captured_at).to eq(nil)
      end

      it 'paymentのrefunded_atが登録されていること' do
        request_completed
        expect(payment.reload.refunded_at).not_to eq(nil)
      end
    end

    context 'カート内のチケットとオーダーが一致しない場合' do
      context '異なるチケットが含まれる場合' do
        let(:orders) do
          [
            { ticket_id: ticket5.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
          ]
        end

        let(:ticket5) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

        it 'エラーが発生すること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
        end

        it '返金日時に日付が入っていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'カートのチケットが多い場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
            { ticket_id: ticket5.id, option_id: nil }
          ]
        end

        let(:ticket5) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

        it 'エラーが発生すること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
        end

        it '返金日時に日付が入っていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'カートのチケット少ない場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil }
          ]
        end

        it 'エラーが発生すること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
        end

        it '返金日時に日付が入っていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end

      context 'オーダーのチケットが多い場合' do
        before do
          create(:ticket_reserve, order: order, ticket: ticket5)
        end

        let(:ticket5) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

        it 'エラーが発生すること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
        end

        it '返金日時に日付が入っていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(order.reload.returned_at).not_to eq(nil)
        end

        it 'paymentのcaptured_atが登録されていないこと' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.captured_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていること' do
          expect do
            request_completed[:error]
          end.to raise_error(FatalSixgramPaymentError)
          expect(payment.reload.refunded_at).not_to eq(nil)
        end
      end
    end

    context 'カート内のオプションとオーダーが一致しない場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option.id },
          { ticket_id: ticket2.id, option_id: seat_type_option.id },
          { ticket_id: ticket3.id, option_id: nil },
          { ticket_id: ticket4.id, option_id: nil }
        ]
      end
      let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }

      it 'エラーが発生すること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
      end

      it '返金日時に日付が入っていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(order.reload.returned_at).not_to eq(nil)
      end

      it 'paymentのcaptured_atが登録されていないこと' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.captured_at).to eq(nil)
      end

      it 'paymentのrefunded_atが登録されていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.refunded_at).not_to eq(nil)
      end
    end

    context 'カート内のクーポンとオーダーが一致しない場合' do
      let(:coupon_id) { user_coupon.coupon.id }
      let(:user_coupon) { create(:user_coupon, user: user) }
      let(:user_coupon_1) { create(:user_coupon) }
      let(:order) { create(:order, total_price: total_price, user_coupon: user_coupon_1) }

      it 'エラーが発生すること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
      end

      it '返金日時に日付が入っていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(order.reload.returned_at).not_to eq(nil)
      end

      it 'paymentのcaptured_atが登録されていないこと' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.captured_at).to eq(nil)
      end

      it 'paymentのrefunded_atが登録されていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.refunded_at).not_to eq(nil)
      end

      context '6gram側ですでに返金済みの場合' do
        let(:charge_id) { '413111' }

        it 'エラーが発生すること' do
          expect do
            request_completed[:error]
          end.to raise_error(CustomError)
        end

        it 'paymentのステータスが支払確定失敗で、返金日時がnilであること（与信OK放置状態）' do
          expect do
            request_completed[:error]
          end.to raise_error(CustomError)
          expect(payment.reload.failed_capture?).to be true
          expect(order.reload.returned_at).to eq(nil)
        end

        it 'paymentのrefunded_atが登録されていないこと' do
          expect do
            request_completed[:error]
          end.to raise_error(CustomError)
          expect(payment.reload.refunded_at).to eq(nil)
        end
      end
    end
  end

  describe '#request_completed', :sales_jwt_mock do
    subject(:request_completed) do
      described_class.request_completed(user, charge_id)
    end

    before do
      create(:ticket_reserve, order: order, ticket: ticket1, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket2, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket3, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket4, seat_type_option: nil)

      cart.replace_tickets(orders, coupon_id, campaign_code)
    end

    let(:user) { create(:user, :with_profile) }
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type) { create(:template_seat_type, price: 1000) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket3) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
    let(:ticket4) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

    let(:order) { create(:order, total_price: total_price) }
    let!(:payment) { create(:payment, order: order, charge_id: charge_id, payment_progress: :requesting_payment) }
    let(:total_price) { 6000 }
    let(:charge_id) { 'charge_id' }

    let(:cart) { Cart.new(user) }
    let(:orders) do
      [
        { ticket_id: ticket1.id, option_id: nil },
        { ticket_id: ticket2.id, option_id: nil },
        { ticket_id: ticket3.id, option_id: nil },
        { ticket_id: ticket4.id, option_id: nil }
      ]
    end
    let(:coupon_id) { nil }
    let(:campaign_code) { nil }

    context 'キャンペーンが有効の場合' do
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.yesterday) }

      let(:campaign_code) { campaign.code }

      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      it 'paymentのcaptured_atが登録されていること' do
        request_completed
        expect(payment.reload.captured_at).not_to eq(nil)
      end
    end

    context '現在時刻がキャンペーンの終了日時を過ぎている場合' do
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.yesterday, end_at: Time.zone.now.since(10.seconds)) }

      let(:campaign_code) { campaign.code }

      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
        travel_to campaign.end_at.since(1.second)
      end

      it 'エラーが発生すること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
      end

      it '返金日時に日付が入っていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(order.reload.returned_at).not_to eq(nil)
      end

      it 'paymentのcaptured_atが登録されていないこと' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.captured_at).to eq(nil)
      end

      it 'paymentのrefunded_atが登録されていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.refunded_at).not_to eq(nil)
      end
    end

    context 'キャンペーンが停止済みの場合' do
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.yesterday, terminated_at: Time.zone.now.since(10.seconds)) }

      let(:campaign_code) { campaign.code }

      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
        travel_to campaign.terminated_at.since(1.second)
      end

      it 'エラーが発生すること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
      end

      it '返金日時に日付が入っていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(order.reload.returned_at).not_to eq(nil)
      end

      it 'paymentのcaptured_atが登録されていないこと' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.captured_at).to eq(nil)
      end

      it 'paymentのrefunded_atが登録されていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.refunded_at).not_to eq(nil)
      end
    end

    context 'キャンペーンが使用ユーザー数に達している場合' do
      let(:user_a) { create(:user) }
      let(:user_b) { create(:user) }
      let(:order_a) { create(:order, :payment_captured, user: user_a) }
      let(:order_b) { create(:order, :payment_captured, user: user_b) }

      let(:campaign) { create(:campaign, approved_at: Time.zone.now.yesterday, usage_limit: 2) }

      let(:campaign_code) { campaign.code }

      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
        # カートを更新した後、usage_limit個のキャンペーン使用レコードを作成
        create(:campaign_usage, campaign: campaign, order: order_a)
        create(:campaign_usage, campaign: campaign, order: order_b)
      end

      it 'エラーが発生すること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
      end

      it '返金日時に日付が入っていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(order.reload.returned_at).not_to eq(nil)
      end

      it 'paymentのcaptured_atが登録されていないこと' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.captured_at).to eq(nil)
      end

      it 'paymentのrefunded_atが登録されていること' do
        expect do
          request_completed[:error]
        end.to raise_error(FatalSixgramPaymentError)
        expect(payment.reload.refunded_at).not_to eq(nil)
      end
    end
  end

  describe '#refund', :sales_jwt_mock do
    subject(:refund_request) do
      described_class.refund(order.id)
    end

    before do
      ticket_reserve1 = create(:ticket_reserve, order: order, ticket: ticket1, seat_type_option: nil)
      ticket_reserve2 = create(:ticket_reserve, order: order, ticket: ticket2, seat_type_option: nil)
      ticket_reserve3 = create(:ticket_reserve, order: order, ticket: ticket3, seat_type_option: nil)
      ticket_reserve4 = create(:ticket_reserve, order: order, ticket: ticket4, seat_type_option: nil)
      ticket1.update(purchase_ticket_reserve_id: ticket_reserve1.id)
      ticket2.update(purchase_ticket_reserve_id: ticket_reserve2.id)
      ticket3.update(purchase_ticket_reserve_id: ticket_reserve3.id)
      ticket4.update(purchase_ticket_reserve_id: ticket_reserve4.id)
    end

    let(:user) { create(:user, :with_profile) }

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type) { create(:template_seat_type, price: 1000) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket3) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket4) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }

    let(:order) { create(:order, payment: payment) }
    let(:payment) { create(:payment, charge_id: charge_id, payment_progress: :captured) }

    let(:charge_id) { 'charge_id' }

    context 'リクエストが成功した場合' do
      it '返金処理が正常に行われること' do
        travel_to('2021-01-01 8:00') do
          refund_request
          expect(payment.reload.payment_progress).to eq('refunded')
          expect(order.reload.returned_at).to eq(Time.zone.local(2021, 1, 1, 8, 0, 0))
          expect(user.tickets).to eq([])
          expect(order.tickets.all?(&:not_for_sale?)).to be true
          expect(order.tickets.all? { |t| t.purchase_ticket_reserve_id.nil? && t.current_ticket_reserve_id.nil? }).to be true
          expect(payment.reload.refunded_at).to eq(Time.zone.local(2021, 1, 1, 8, 0, 0))
        end
      end
    end

    context '返金APIのリクエストに失敗した場合' do
      context '6gram側ですでに返金済みの場合' do
        let(:charge_id) { '413111' }

        it 'エラーが帰ること' do
          expect do
            refund_request
          end.to raise_error(CustomError)
          expect(payment.reload.captured?).to be true
          expect(order.reload.returned_at).to eq(nil)
          expect(user.tickets).to eq([ticket1, ticket2, ticket3, ticket4])
          expect(user.tickets.all?(&:sold?)).to be true
          expect(payment.reload.refunded_at).to eq(nil)
        end
      end

      context '6gram側で存在しないチャージIDの場合' do
        let(:charge_id) { '413114' }

        it 'エラーが帰ること' do
          expect do
            refund_request
          end.to raise_error(CustomError)
          expect(payment.reload.captured?).to be true
          expect(order.reload.returned_at).to eq(nil)
          expect(user.tickets).to eq([ticket1, ticket2, ticket3, ticket4])
          expect(user.tickets.all?(&:sold?)).to be true
          expect(payment.reload.refunded_at).to eq(nil)
        end
      end
    end
  end
end
