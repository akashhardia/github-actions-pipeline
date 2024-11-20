# frozen_string_literal: true

require 'rails_helper'

describe Serializers::OrderDetail, type: :model do
  let(:order) { create(:order, :with_ticket_reserve_in_admission) }
  let(:order_detail) { described_class.create(order) }
  let(:ticket) { order.tickets.first }
  let(:seat_type_option) { ticket.seat_type.seat_type_options.find(order.ticket_reserves.first.seat_type_option_id) }
  let(:ticket_list) do
    {
      optionTitle: seat_type_option.title,
      row: ticket.row,
      seatNumber: ticket.seat_number
    }
  end

  it 'attributesに対して想定した値が入っていること' do
    expect(order_detail.ticket_reserves).to eq(order.ticket_reserves)
    expect(order_detail.ticket_list).to eq([ticket_list])
    expect(order_detail.total_price).to eq(order.total_price)
    expect(order_detail.payment).to eq('ご登録済みクレジットカード')
    expect(order_detail.area_name).to eq(ticket.area_name)
  end
end
