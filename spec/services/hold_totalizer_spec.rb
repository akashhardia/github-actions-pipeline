# frozen_string_literal: true

require 'rails_helper'

describe HoldTotalizer, type: :model do
  let(:hold) { create(:hold) }
  let(:hold_daily1) { create(:hold_daily, hold: hold) }
  let(:hold_daily2) { create(:hold_daily, hold: hold) }
  let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
  let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
  let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
  let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(5..9).hour, force_sales_stop_at: Time.zone.now - rand(0..4).hour) }

  describe 'order_total_price' do
    subject(:execute_order_total_price) do
      instance = described_class.new(hold)
      instance.order_total_price
    end

    before do
      # template_seat_type の価格は各1,000円
      order1 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
      order2 = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2)
      create(:payment, order: order1)
      create(:payment, order: order2)
    end

    context '有効な処理の場合' do
      it 'holdに紐づくorderのtotal_priceの合計値を取得できる' do
        expect(execute_order_total_price).to eq(2000)
      end
    end
  end

  describe 'order_total_number' do
    subject(:execute_order_total_number) do
      instance = described_class.new(hold)
      instance.order_total_number
    end

    before do
      stub_const('ORDER_NUMBER_1', rand(1..10))
      stub_const('ORDER_NUMBER_2', rand(1..10))
      stub_const('TOTAL_ORDER_NUMBER', ORDER_NUMBER_1 + ORDER_NUMBER_2)

      ORDER_NUMBER_1.times do
        order = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale1)
        create(:payment, order: order)
      end

      ORDER_NUMBER_2.times do
        order = create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale2)
        create(:payment, order: order)
      end
    end

    context '有効な処理の場合' do
      it 'holdに紐づくorder数の合計値を取得できる' do
        expect(execute_order_total_number).to eq(TOTAL_ORDER_NUMBER)
      end
    end
  end
end
