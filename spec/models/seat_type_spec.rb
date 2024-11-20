# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_types
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_type_id   :bigint           not null
#  seat_sale_id          :bigint           not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_seat_types_on_master_seat_type_id    (master_seat_type_id)
#  index_seat_types_on_seat_sale_id           (seat_sale_id)
#  index_seat_types_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
require 'rails_helper'

RSpec.describe SeatType, type: :model do
  describe 'validationの確認' do
    let(:seat_sale) { create(:seat_sale) }
    let(:master_seat_type) { create(:master_seat_type, name: 'seat type') }
    let(:template_seat_type) { create(:template_seat_type) }

    it 'master_seat_type関連がなければerrorになること' do
      seat_type = described_class.new(seat_sale: seat_sale, template_seat_type: template_seat_type)
      expect(seat_type.valid?).to eq false
    end

    it 'template_seat_type関連がなければerrorになること' do
      seat_type = described_class.new(master_seat_type: master_seat_type, seat_sale: seat_sale)
      expect(seat_type.valid?).to eq false
    end

    it 'seat_sale関連がなければerrorになること' do
      seat_type = described_class.new(template_seat_type: template_seat_type, master_seat_type: master_seat_type)
      expect(seat_type.valid?).to eq false
    end
  end
end
