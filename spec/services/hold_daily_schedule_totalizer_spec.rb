# frozen_string_literal: true

require 'rails_helper'

describe HoldDailyScheduleTotalizer, type: :model do
  before do
    create(:payment, order: order)
  end

  let(:order) { create(:order, :with_ticket_and_build_reserves, seat_sale: seat_sale) }
  let(:hold) { create(:hold, track_code: '01') }
  let(:hold_daily) { create(:hold_daily, hold: hold) }
  let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily, daily_no: 0) }
  let(:seat_sale) { create(:seat_sale, hold_daily_schedule: hold_daily_schedule, sales_status: 'on_sale', sales_start_at: Time.zone.now - rand(0..4).hour) }

  describe 'order_total_price' do
    subject(:execute_order_total_price) do
      instance = described_class.new(hold_daily_schedule)
      instance.order_total_price
    end

    context '有効な処理の場合' do
      it 'hold_dailyに紐づくorderのtotal_priceの合計値を取得できる' do
        expect(execute_order_total_price).to eq(1000)
      end
    end
  end

  describe 'order_total_number' do
    subject(:execute_order_total_number) do
      instance = described_class.new(hold_daily_schedule)
      instance.order_total_number
    end

    context '有効な処理の場合' do
      it 'hold_dailyに紐づくorder数の合計値を取得できる' do
        expect(execute_order_total_number).to eq(1)
      end
    end
  end
end
