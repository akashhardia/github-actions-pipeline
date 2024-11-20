# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_areas
#
#  id                  :bigint           not null, primary key
#  displayable         :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  entrance_id         :bigint
#  master_seat_area_id :bigint           not null
#  seat_sale_id        :bigint           not null
#
# Indexes
#
#  index_seat_areas_on_entrance_id          (entrance_id)
#  index_seat_areas_on_master_seat_area_id  (master_seat_area_id)
#  index_seat_areas_on_seat_sale_id         (seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (entrance_id => entrances.id)
#  fk_rails_...  (master_seat_area_id => master_seat_areas.id)
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#
require 'rails_helper'

RSpec.describe SeatArea, type: :model do
  describe 'validationの確認' do
    let(:seat_sale) { create(:seat_sale) }
    let(:master_seat_area) { create(:master_seat_area) }

    it 'areaがなければerrorになること' do
      seat_area = described_class.new(seat_sale: seat_sale)
      expect(seat_area.valid?).to eq false
    end

    it 'seat_saleがなければerrorになること' do
      seat_area = described_class.new(master_seat_area: master_seat_area)
      expect(seat_area.valid?).to eq false
    end
  end
end
