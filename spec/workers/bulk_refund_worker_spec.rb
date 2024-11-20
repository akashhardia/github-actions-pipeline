# frozen_string_literal: true

require 'rails_helper'
RSpec.describe BulkRefundWorker, type: :worker do
  describe 'perform' do
    subject(:perform_async) do
      described_class.new.perform(seat_sale.id)
    end

    before do
      create(:ticket_reserve, order: order, ticket: ticket1, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket2, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket3, seat_type_option: nil)
      create(:ticket_reserve, order: order, ticket: ticket4, seat_type_option: nil)
      create(:ticket_reserve, order: order2, ticket: ticket2_1, seat_type_option: nil)
      create(:ticket_reserve, order: order2, ticket: ticket2_2, seat_type_option: nil)
      create(:ticket_reserve, order: order2, ticket: ticket2_3, seat_type_option: nil)
      create(:ticket_reserve, order: order3, ticket: ticket3_1, seat_type_option: nil)
      create(:ticket_reserve, order: order3, ticket: ticket3_2, seat_type_option: nil)
      create(:ticket_reserve, order: order4, ticket: ticket4_1, seat_type_option: nil)
      create(:ticket_reserve, order: order4, ticket: ticket4_2, seat_type_option: nil)
      create(:ticket_reserve, order: order5, ticket: ticket5, seat_type_option: nil)
      create(:ticket_reserve, order: order6, ticket: ticket6, seat_type_option: nil)
      create(:ticket_reserve, order: order7, ticket: ticket7, seat_type_option: nil)
    end

    let(:user) { create(:user, :with_profile) }
    let(:user_other) { create(:user, :with_profile) }

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type) { create(:template_seat_type, price: 1000) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket3) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket4) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket2_1) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket2_2) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket2_3) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user, status: :sold) }
    let(:ticket3_1) { create(:ticket, seat_type: seat_type, seat_area: seat_area, status: :not_for_sale) }
    let(:ticket3_2) { create(:ticket, seat_type: seat_type, seat_area: seat_area, status: :not_for_sale) }
    let(:ticket4_1) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user_other, status: :sold) }
    let(:ticket4_2) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user_other, status: :sold) }
    let(:ticket5) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user_other, status: :sold) }
    let(:ticket6) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user_other, status: :sold) }
    let(:ticket7) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user: user_other, status: :sold) }

    let(:order) { create(:order, payment: payment, seat_sale_id: seat_sale.id) }
    let(:order2) { create(:order, payment: payment2, seat_sale_id: seat_sale.id) }
    let(:order3) { create(:order, payment: payment3, seat_sale_id: seat_sale.id, returned_at: Date.new(2021, 0o1, 0o1)) }
    let(:order4) { create(:order, payment: payment4, seat_sale_id: seat_sale.id) }
    # payment_progressがrequesting_paymentのorder
    let(:order5) { create(:order, payment: payment5, seat_sale_id: seat_sale.id) }
    let(:order6) { create(:order, payment: payment6, seat_sale_id: seat_sale.id) }
    let(:order7) { create(:order, payment: payment7, seat_sale_id: seat_sale.id) }

    let(:payment) { create(:payment, charge_id: charge_id, payment_progress: :captured) }
    let(:payment2) { create(:payment, charge_id: charge_id2, payment_progress: :captured) }
    let(:payment3) { create(:payment, charge_id: charge_id3, payment_progress: :refunded, refunded_at: Date.new(2021, 0o1, 0o1)) }
    let(:payment4) { create(:payment, charge_id: charge_id4, payment_progress: :captured) }
    let(:payment5) { create(:payment, charge_id: charge_id5, payment_progress: :requesting_payment) }
    let(:payment6) { create(:payment, charge_id: charge_id6, payment_progress: :requesting_payment) }
    let(:payment7) { create(:payment, charge_id: charge_id7, payment_progress: :requesting_payment) }

    let(:charge_id) { 'charge_id' }
    let(:charge_id2) { 'charge_id2' }
    let(:charge_id3) { 'charge_id3' }
    let(:charge_id4) { 'charge_id4' }
    let(:charge_id5) { '211111' } # charge_statusのauthorizedがtrue
    let(:charge_id6) { '211111' } # charge_statusのauthorizedがtrue
    let(:charge_id7) { '211111' } # charge_statusのauthorizedがtrue

    context 'workerが成功した場合' do
      it '返金処理が正常に行われること' do
        perform_async
        expect(user.tickets).to eq([])
        expect(user.tickets.all?(&:not_for_sale?)).to be true
        expect(payment.reload.payment_progress).to eq('refunded')
        expect(order.reload.returned_at).not_to eq(nil)
        expect(order.reload.refund_error_message).to eq(nil)
        expect(payment.reload.refunded_at).not_to eq(nil)
        expect(payment2.reload.payment_progress).to eq('refunded')
        expect(order2.reload.returned_at).not_to eq(nil)
        expect(order2.reload.refund_error_message).to eq(nil)
        expect(payment2.reload.refunded_at).not_to eq(nil)

        expect(user_other.tickets).to eq([])
        expect(user_other.tickets.all?(&:not_for_sale?)).to be true
        expect(payment3.reload.payment_progress).to eq('refunded')
        expect(payment3.reload.refunded_at).to eq(payment3.refunded_at)
        expect(order3.reload.returned_at).to eq(order3.returned_at)
        expect(order3.reload.refund_error_message).to eq(nil)
        expect(payment4.reload.payment_progress).to eq('refunded')
        expect(order4.reload.returned_at).not_to eq(nil)
        expect(order4.reload.refund_error_message).to eq(nil)
        expect(payment4.reload.refunded_at).not_to eq(nil)
        expect(payment5.reload.payment_progress).to eq('refunded')
        expect(order5.reload.returned_at).not_to eq(nil)
        expect(order5.reload.refund_error_message).to eq(nil)
        expect(payment5.reload.refunded_at).not_to eq(nil)
        expect(payment6.reload.payment_progress).to eq('refunded')
        expect(order6.reload.returned_at).not_to eq(nil)
        expect(order6.reload.refund_error_message).to eq(nil)
        expect(payment6.reload.refunded_at).not_to eq(nil)
        expect(payment7.reload.payment_progress).to eq('refunded')
        expect(order7.reload.returned_at).not_to eq(nil)
        expect(order7.reload.refund_error_message).to eq(nil)
        expect(payment7.reload.refunded_at).not_to eq(nil)
      end

      it 'SeatSaleの一括変更実行終了時刻が登録されること' do
        perform_async
        expect(seat_sale.reload.refund_end_at).not_to eq(nil)
      end
    end

    context '一部返金APIのリクエストに失敗した場合' do
      context '6gram側でエラーのチャージIDがある場合' do
        let(:charge_id) { '413111' }
        let(:charge_id4) { '413114' }
        let(:charge_id6) { '211114' } # charge_statusのauthorizedがfalse
        let(:charge_id7) { '211115' } # charge_statusをチェックした際にresource not foundが返ってくる

        it 'エラー対象のレコードにエラーが登録されること' do
          perform_async
          expect(user.tickets).to eq([ticket1, ticket2, ticket3, ticket4])
          expect(ticket1.reload.status).to eq('sold')
          expect(ticket2.reload.status).to eq('sold')
          expect(ticket3.reload.status).to eq('sold')
          expect(ticket4.reload.status).to eq('sold')
          expect(ticket2_1.reload.status).to eq('not_for_sale')
          expect(ticket2_2.reload.status).to eq('not_for_sale')
          expect(ticket2_3.reload.status).to eq('not_for_sale')
          # order1　already_refunded
          expect(payment.reload.payment_progress).to eq('captured')
          expect(order.reload.returned_at).to eq(nil)
          expect(order.reload.refund_error_message).to include 'already_refunded'
          expect(payment.reload.refunded_at).to eq(nil)
          # order2　返金正常終了
          expect(payment2.reload.payment_progress).to eq('refunded')
          expect(order2.reload.returned_at).not_to eq(nil)
          expect(order2.reload.refund_error_message).to eq(nil)
          expect(payment2.reload.refunded_at).not_to eq(nil)

          expect(user_other.tickets).to eq([ticket4_1, ticket4_2, ticket6, ticket7])
          expect(ticket3_1.reload.status).to eq('not_for_sale')
          expect(ticket3_2.reload.status).to eq('not_for_sale')
          expect(ticket4_1.reload.status).to eq('sold')
          expect(ticket4_2.reload.status).to eq('sold')
          # order3　既に返金済みのデータが更新されないこと
          expect(payment3.reload.payment_progress).to eq('refunded')
          expect(order3.reload.returned_at).to eq(order3.returned_at)
          expect(order3.reload.refund_error_message).to eq(nil)
          expect(payment3.reload.refunded_at).to eq(payment3.refunded_at)
          # order4　resource_not_found
          expect(payment4.reload.payment_progress).to eq('captured')
          expect(order4.reload.returned_at).to eq(nil)
          expect(order4.reload.refund_error_message).to include 'resource_not_found'
          expect(payment4.reload.refunded_at).to eq(nil)
          # order5　返金正常終了
          expect(payment5.reload.payment_progress).to eq('refunded')
          expect(order5.reload.returned_at).not_to eq(nil)
          expect(order5.reload.refund_error_message).to eq(nil)
          expect(payment5.reload.refunded_at).not_to eq(nil)
          # order6　返金対象にならないので何も変化なし
          expect(payment6.reload.payment_progress).to eq('requesting_payment')
          expect(order6.reload.returned_at).to eq(nil)
          expect(order6.reload.refund_error_message).to eq(nil)
          expect(payment6.reload.refunded_at).to eq(nil)
          # order7　返金対象にならないが返金失敗のエラーメッセージを入れる
          expect(payment7.reload.payment_progress).to eq('requesting_payment')
          expect(order7.reload.returned_at).to eq(nil)
          expect(order7.reload.refund_error_message).to include 'resource not found'
          expect(payment7.reload.refunded_at).to eq(nil)
        end
      end
    end
  end
end
