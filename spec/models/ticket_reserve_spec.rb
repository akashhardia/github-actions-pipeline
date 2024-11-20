# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_reserves
#
#  id                         :bigint           not null, primary key
#  transfer_at                :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  next_ticket_reserve_id     :bigint
#  order_id                   :bigint           not null
#  previous_ticket_reserve_id :bigint
#  seat_type_option_id        :bigint
#  ticket_id                  :bigint
#  transfer_from_user_id      :integer
#  transfer_to_user_id        :integer
#
# Indexes
#
#  fk_rails_42a1e40625                           (previous_ticket_reserve_id)
#  fk_rails_8e89099d87                           (next_ticket_reserve_id)
#  index_ticket_reserves_on_order_id             (order_id)
#  index_ticket_reserves_on_seat_type_option_id  (seat_type_option_id)
#  index_ticket_reserves_on_ticket_id            (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (next_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (previous_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (seat_type_option_id => seat_type_options.id)
#  fk_rails_...  (ticket_id => tickets.id)
#
require 'rails_helper'

RSpec.describe TicketReserve, type: :model do
  describe 'validationの確認' do
    let(:order) { create(:order, :with_ticket_reserve_in_admission) }
    let(:ticket) { create(:ticket) }

    it 'ticket_idがなければerrorになること' do
      ticket_reserve = described_class.new(order: order)
      expect(ticket_reserve.valid?).to eq false
    end
  end

  describe '#admission_ticket' do
    subject(:admission_ticket) { described_class.admission_ticket(user) }

    before do
      create(:ticket_reserve, order: order)
    end

    let(:user) { create(:user) }
    let(:order) { create(:order, user: user, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }

    context 'ユーザーが閉場したイベントのチケットを予約している場合' do
      before do
        create(:ticket_reserve, order: closed_order)
      end

      let(:closed_order) { create(:order, seat_sale: closed_seat_sale) }
      let(:closed_seat_sale) { create(:seat_sale, :after_closing) }

      it '閉場したイベントのチケット予約は含まれないこと' do
        ticket_reserves = admission_ticket
        expect(ticket_reserves.length).to eq 1
        exclude_ticket_reserve = described_class.find_by(order: closed_order)
        expect(ticket_reserves).not_to include exclude_ticket_reserve
      end
    end

    context '他のユーザーが同じイベントのチケットを購入している場合' do
      before do
        create(:ticket_reserve, order: other_user_order)
      end

      let(:other_user_order) { create(:order, user: other_user, seat_sale: seat_sale) }
      let(:other_user) { create(:user) }

      it '他のユーザーのチケット予約は含まれないこと' do
        ticket_reserves = admission_ticket
        expect(ticket_reserves.length).to eq 1
        exclude_ticket_reserve = described_class.find_by(order: other_user_order)
        expect(ticket_reserves).not_to include exclude_ticket_reserve
      end
    end
  end

  describe '#not_transfer_ticket_reserve' do
    subject(:not_transfer_ticket_reserve) { described_class.not_transfer_ticket_reserve }

    let(:transfer_ticket_reserve) { create(:ticket_reserve, transfer_at: Time.zone.now) }

    before do
      create(:ticket_reserve)
    end

    it '譲渡済みのチケット予約が含まれないこと' do
      ticket_reserves = not_transfer_ticket_reserve

      expect(ticket_reserves.length).to eq 1
      expect(ticket_reserves).not_to include transfer_ticket_reserve
    end
  end

  describe '#filter_ticket_reserves' do
    subject(:filter_ticket_reserves) { ticket1.ticket_reserves.filter_ticket_reserves }

    let(:ticket1) { create(:ticket, status: :sold) }

    context 'TicketReserveが３つある場合（requesting_paymentが２つ、capturedが１つあるケース）' do
      let(:order1) { create(:order, order_type: :purchase) }
      let(:order2) { create(:order, order_type: :purchase) }
      let(:order3) { create(:order, order_type: :purchase) }
      let!(:ticket_reserve3_1) { create(:ticket_reserve, order: order3, ticket: ticket1) }

      before do
        create(:ticket_reserve, order: order1, ticket: ticket1)
        create(:ticket_reserve, order: order2, ticket: ticket1)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :requesting_payment)
        create(:payment, order: order3, payment_progress: :captured)
      end

      it '購入済みのチケット予約だけが返されること' do
        ticket_reserves = filter_ticket_reserves

        expect(ticket_reserves.length).to eq 1
        expect(ticket_reserves.first.id).to eq(ticket_reserve3_1.id)
      end
    end

    context '管理者譲渡の場合' do
      let(:order) { create(:order, order_type: :admin_transfer) }
      let!(:ticket_reserve) { create(:ticket_reserve, order: order, ticket: ticket1) }

      it '対象のチケット予約が返されること' do
        ticket_reserves = filter_ticket_reserves

        expect(ticket_reserves.length).to eq 1
        expect(ticket_reserves.first.id).to eq(ticket_reserve.id)
      end
    end

    context '購入なのにpaymentがない場合（イレギュラーケース）' do
      let(:order) { create(:order, order_type: :purchase) }

      before do
        create(:ticket_reserve, order: order, ticket: ticket1)
      end

      it 'チケット予約が0件で帰ること' do
        ticket_reserves = filter_ticket_reserves

        expect(ticket_reserves.length).to eq 0
      end
    end
  end
end
