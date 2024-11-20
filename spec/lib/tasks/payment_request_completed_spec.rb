# frozen_string_literal: true

require 'rails_helper'
require 'rake_helper'

describe 'payment raketask' do # rubocop:disable RSpec/DescribeClass
  describe 'payment:request_completed' do
    let(:payment_request_completed_task) { Rake.application['payment:request_completed'] }
    let(:user) { create(:user, :with_profile) }
    let(:user2) { create(:user, :with_profile) }
    let(:user3) { create(:user, :with_profile) }
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type) { create(:template_seat_type, price: 1000) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:tickets) { create_list(:ticket, 6, seat_type: seat_type, seat_area: seat_area) }
    let(:orders) do
      [
        [{ ticket_id: tickets[0].id, option_id: nil }, { ticket_id: tickets[1].id, option_id: nil }],
        [{ ticket_id: tickets[2].id, option_id: nil }, { ticket_id: tickets[3].id, option_id: nil }],
        [{ ticket_id: tickets[4].id, option_id: nil }, { ticket_id: tickets[5].id, option_id: nil }]
      ]
    end
    let(:coupon_id) { nil }
    let(:campaign_code) { nil }
    let(:authorized_false_charge_id) { 211114 }
    let(:already_captured_charge_id) { 412111 }
    let(:payment1) { Payment.new(charge_id: '1111', payment_progress: :requesting_payment, created_at: Time.zone.now - 46.minutes) }
    let(:payment2) { Payment.new(charge_id: already_captured_charge_id, payment_progress: :requesting_payment, created_at: Time.zone.now - 46.minutes) }
    let(:payment3) { Payment.new(charge_id: authorized_false_charge_id, payment_progress: :requesting_payment, created_at: Time.zone.now - 46.minutes) }

    before do
      cart = Cart.new(user)
      cart.replace_tickets(orders[0], coupon_id, campaign_code)
      cart.replace_cart_charge_id(payment1.charge_id)
      ticket_reserves = cart.orders[:orders].map do |order|
        TicketReserve.new(ticket_id: order[:ticket_id], seat_type_option_id: order[:option_id])
      end
      order = Order.new(user: user, payment: payment1, order_at: Time.zone.now, order_type: :purchase,
                        total_price: cart.purchase_order.total_price, seat_sale: cart.seat_sale)
      order.ticket_reserves << ticket_reserves

      order.save!
    end

    context 'authorized: true、captured: falseの場合' do
      it 'Paymentが更新されること' do
        expect { payment_request_completed_task.invoke }.to change { payment1.reload.payment_progress }.from('requesting_payment').to('captured')
        expect(payment1.reload.captured_at).not_to eq(nil)
      end

      it 'Ticketがユーザーに紐づくこと' do
        payment_request_completed_task.invoke
        expect(user.tickets).to eq([tickets[0], tickets[1]])
        expect(user.tickets.all?(&:sold?)).to be true
      end

      it '決済後にメールが通知されること' do
        perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
          expect { payment_request_completed_task.invoke }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        expect(ActionMailer::Base.deliveries.map(&:to)).to include [user.profile.email]
      end

      it 'Ticketが持つ購入時と有効なTicketReserveのIDが更新されること' do
        payment_request_completed_task.invoke
        payment1.order.ticket_reserves.each do |tr|
          ticket = tr.ticket
          expect(ticket.reload.purchase_ticket_reserve_id).to eq(tr.id)
          expect(ticket.reload.current_ticket_reserve_id).to eq(tr.id)
        end
      end
    end

    context 'authorized: true、captured: trueの決済が含まれている場合' do
      before do
        cart = Cart.new(user2)
        cart.replace_tickets(orders[1], coupon_id, campaign_code)
        cart.replace_cart_charge_id(payment2.charge_id)
        ticket_reserves = cart.orders[:orders].map do |order|
          TicketReserve.new(ticket_id: order[:ticket_id], seat_type_option_id: order[:option_id])
        end
        order = Order.new(user: user2, payment: payment2, order_at: Time.zone.now, order_type: :purchase,
                          total_price: cart.purchase_order.total_price, seat_sale: cart.seat_sale)
        order.ticket_reserves << ticket_reserves

        order.save!
      end

      it 'Paymentが更新されること' do
        expect { payment_request_completed_task.invoke }.to change { payment1.reload.payment_progress }.from('requesting_payment').to('captured').and \
          change { payment2.reload.payment_progress }.from('requesting_payment').to('captured')
        expect(payment1.reload.captured_at).not_to eq(nil)
        expect(payment2.reload.captured_at).not_to eq(nil)
      end

      it 'Ticketがユーザーに紐づくこと' do
        payment_request_completed_task.invoke
        expect(user.tickets).to eq([tickets[0], tickets[1]])
        expect(user.tickets.all?(&:sold?)).to be true
        expect(user2.tickets).to eq([tickets[2], tickets[3]])
        expect(user2.tickets.all?(&:sold?)).to be true
      end

      it '決済後にメールが通知されること' do
        perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
          expect { payment_request_completed_task.invoke }.to change { ActionMailer::Base.deliveries.count }.by(2)
        end

        expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(user.profile.email, user2.profile.email)
      end

      it 'Ticketが持つ購入時と有効なTicketReserveのIDが更新されること' do
        payment_request_completed_task.invoke
        payment1.order.ticket_reserves.each do |tr|
          ticket = tr.ticket
          expect(ticket.reload.purchase_ticket_reserve_id).to eq(tr.id)
          expect(ticket.reload.current_ticket_reserve_id).to eq(tr.id)
        end
        payment2.order.ticket_reserves.each do |tr|
          ticket = tr.ticket
          expect(ticket.reload.purchase_ticket_reserve_id).to eq(tr.id)
          expect(ticket.reload.current_ticket_reserve_id).to eq(tr.id)
        end
      end
    end

    context 'authorized: falseの決済が含まれている場合' do
      before do
        cart = Cart.new(user3)
        cart.replace_tickets(orders[1], coupon_id, campaign_code)
        cart.replace_cart_charge_id(payment3.charge_id)
        ticket_reserves = cart.orders[:orders].map do |order|
          TicketReserve.new(ticket_id: order[:ticket_id], seat_type_option_id: order[:option_id])
        end
        order = Order.new(user: user3, payment: payment3, order_at: Time.zone.now, order_type: :purchase,
                          total_price: cart.purchase_order.total_price, seat_sale: cart.seat_sale)
        order.ticket_reserves << ticket_reserves

        order.save!
      end

      it 'Paymentが更新されること' do
        expect { payment_request_completed_task.invoke }.to change { payment1.reload.payment_progress }.from('requesting_payment').to('captured').and \
          change { payment3.reload.payment_progress }.from('requesting_payment').to('failed_request')
        expect(payment1.reload.captured_at).not_to eq(nil)
        expect(payment3.reload.captured_at).to eq(nil)
      end

      it '返金リクエストがされること' do
        allow(SixgramPayment::Service).to receive(:refund).with(payment3.charge_id).and_return(OpenStruct.new(ok?: true))
        payment_request_completed_task.invoke
        expect(SixgramPayment::Service).to have_received(:refund).with(payment3.charge_id).once
      end

      it '決済に成功したTicketはユーザーに紐づき、決済に失敗したTicketはユーザーに紐づかないこと' do
        payment_request_completed_task.invoke
        expect(user.tickets).to eq([tickets[0], tickets[1]])
        expect(user.tickets.all?(&:sold?)).to be true
        expect(user3.tickets).to eq([])
      end

      it '決済に成功したユーザーは決済後にメールが通知される、決済に失敗したユーザーは決済後にメールが通知されないこと' do
        perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
          expect { payment_request_completed_task.invoke }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end

        expect(ActionMailer::Base.deliveries.map(&:to)).to include [user.profile.email]
        expect(ActionMailer::Base.deliveries.map(&:to)).not_to include [user3.profile.email]
      end

      it 'Ticketが持つ購入時と有効なTicketReserveのIDが更新されること' do
        payment_request_completed_task.invoke
        payment1.order.ticket_reserves.each do |tr|
          ticket = tr.ticket
          expect(ticket.reload.purchase_ticket_reserve_id).to eq(tr.id)
          expect(ticket.reload.current_ticket_reserve_id).to eq(tr.id)
        end
      end

      it '決済に失敗したユーザーのTicketのステータスがavailableであること' do
        payment_request_completed_task.invoke
        expect(payment3.order.tickets.all? { |t| t.reload.available? }).to be true
      end
    end

    context 'Payment作成後、45分以上経過していない場合' do
      let(:payment1) { Payment.new(charge_id: '1111', payment_progress: :requesting_payment) }

      it 'Paymentが更新されないこと' do
        expect { payment_request_completed_task.invoke }.to not_change { payment1.reload.payment_progress }.and \
          not_change { payment1.reload.captured_at }
      end
    end

    context 'Payment.payment_progressが、requesting_payment以外の場合' do
      let(:payment1) { Payment.new(charge_id: '1111', payment_progress: Payment.payment_progresses.except('requesting_payment').keys.sample) }

      it 'Paymentが更新されないこと' do
        expect { payment_request_completed_task.invoke }.to not_change { payment1.reload.payment_progress }.and \
          not_change { payment1.reload.captured_at }
      end
    end

    context 'seat_salesの販売期間を超えている場合' do
      before { seat_sale.update!(sales_start_at: Date.yesterday - 1.hour, sales_end_at: Date.yesterday) }

      it 'Paymentが更新されないこと' do
        expect { payment_request_completed_task.invoke }.to not_change { payment1.reload.payment_progress }.and \
          not_change { payment1.reload.captured_at }
      end
    end

    context '途中で例外が発生した場合' do
      let(:payments) { [payment1, payment3, payment2] }
      let(:users) { [user2, user3] }

      before do
        users.each.with_index(1) do |user, index|
          cart = Cart.new(user)
          cart.replace_tickets(orders[index], coupon_id, campaign_code)
          cart.replace_cart_charge_id(payments[index].charge_id)
          ticket_reserves = cart.orders[:orders].map do |order|
            TicketReserve.new(ticket_id: order[:ticket_id], seat_type_option_id: order[:option_id])
          end
          order = Order.new(user: user, payment: payments[index], order_at: Time.zone.now, order_type: :purchase,
                            total_price: cart.purchase_order.total_price, seat_sale: cart.seat_sale)
          order.ticket_reserves << ticket_reserves

          order.save!
        end
        allow(SixgramPayment::Service).to receive(:refund).and_return(OpenStruct.new(ok?: false))
      end

      it '後続処理は止まらずPaymentの更新が実行されること' do
        expect { payment_request_completed_task.invoke }.to raise_error(StandardError).and \
          change { payment1.reload.payment_progress }.from('requesting_payment').to('captured').and \
            change { payment2.reload.payment_progress }.from('requesting_payment').to('captured').and \
              change { payment3.reload.payment_progress }.from('requesting_payment').to('failed_request')
        expect(payment1.reload.captured_at).not_to eq(nil)
        expect(payment2.reload.captured_at).not_to eq(nil)
        expect(payment3.reload.captured_at).to eq(nil)
      end
    end
  end
end
