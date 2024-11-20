# frozen_string_literal: true

# == Schema Information
#
# Table name: tickets
#
#  id                    :bigint           not null, primary key
#  admission_disabled_at :datetime
#  row                   :string(255)
#  sales_type            :integer          default("single"), not null
#  seat_number           :integer          not null
#  status                :integer          default("available"), not null
#  transfer_uuid         :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_unit_id   :bigint
#  qr_ticket_id          :string(255)
#  seat_area_id          :bigint           not null
#  seat_type_id          :bigint           not null
#  user_id               :bigint
#
# Indexes
#
#  index_tickets_on_master_seat_unit_id  (master_seat_unit_id)
#  index_tickets_on_seat_area_id         (seat_area_id)
#  index_tickets_on_seat_type_id         (seat_type_id)
#  index_tickets_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_unit_id => master_seat_units.id)
#  fk_rails_...  (seat_area_id => seat_areas.id)
#  fk_rails_...  (seat_type_id => seat_types.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe 'TicketSerializer', type: :serializer do
  context 'Ticketシリアライザー使用時' do
    let(:user) { create(:user) }
    let(:ticket1) { create(:ticket, status: :available) }
    let(:ticket2) { create(:ticket, status: :available, user: user) }

    it '想定しているstatusが入っていること' do
      serializer = TicketSerializer.new(ticket1)
      expect(serializer.to_json['status']).to eq('available')
    end

    it 'user_idが埋まっている場合は、statusにsoldが入っていること' do
      serializer = TicketSerializer.new(ticket2)
      expect(serializer.to_json['status']).to eq('sold')
    end
  end
end
