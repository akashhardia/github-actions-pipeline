# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seats
#
#  id                  :bigint           not null, primary key
#  row                 :string(255)
#  sales_type          :integer          not null
#  seat_number         :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  master_seat_area_id :bigint           not null
#  master_seat_type_id :bigint           not null
#  master_seat_unit_id :bigint
#
# Indexes
#
#  index_master_seats_on_master_seat_area_id  (master_seat_area_id)
#  index_master_seats_on_master_seat_type_id  (master_seat_type_id)
#  index_master_seats_on_master_seat_unit_id  (master_seat_unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_area_id => master_seat_areas.id)
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (master_seat_unit_id => master_seat_units.id)
#
require 'rails_helper'

RSpec.describe MasterSeat, type: :model do
  describe 'validationの確認' do
    let(:master_seat_area) { create(:master_seat_area) }
    let(:master_seat_type) { create(:master_seat_type) }
    let(:master_seat_unit) { create(:master_seat_unit) }

    it 'sales_typeがなければerrorになること' do
      master_seat = described_class.new(row: 'A', seat_number: 1, master_seat_area: master_seat_area, master_seat_type: master_seat_type, master_seat_unit: master_seat_unit)
      expect(master_seat.valid?).to eq false
    end

    it 'seat_numberがなければerrorになること' do
      master_seat = described_class.new(row: 'A', sales_type: :single, master_seat_area: master_seat_area, master_seat_type: master_seat_type, master_seat_unit: master_seat_unit)
      expect(master_seat.valid?).to eq false
    end

    it 'master_seat_areaがなければerrorになること' do
      master_seat = described_class.new(row: 'A', seat_number: 1, sales_type: :single, master_seat_type: master_seat_type, master_seat_unit: master_seat_unit)
      expect(master_seat.valid?).to eq false
    end

    it 'master_seat_typeがなければerrorになること' do
      master_seat = described_class.new(row: 'A', seat_number: 1, sales_type: :single, master_seat_area: master_seat_area, master_seat_unit: master_seat_unit)
      expect(master_seat.valid?).to eq false
    end
  end
end
