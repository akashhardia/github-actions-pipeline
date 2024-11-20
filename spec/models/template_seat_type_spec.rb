# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_types
#
#  id                    :bigint           not null, primary key
#  price                 :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_type_id   :bigint           not null
#  template_seat_sale_id :bigint           not null
#
# Indexes
#
#  index_template_seat_types_on_master_seat_type_id    (master_seat_type_id)
#  index_template_seat_types_on_template_seat_sale_id  (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
require 'rails_helper'

RSpec.describe TemplateSeatType, type: :model do
  describe 'validationの確認' do
    let(:master_seat_type) { create(:master_seat_type) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    it 'priceがなければerrorになること' do
      template_seat_type = described_class.new(master_seat_type: master_seat_type, template_seat_sale: template_seat_sale)
      expect(template_seat_type.valid?).to eq false
    end

    it 'master_seat_typeがなければerrorになること' do
      template_seat_type = described_class.new(price: 10_000, template_seat_sale: template_seat_sale)
      expect(template_seat_type.valid?).to eq false
    end

    it 'template_seat_saleがなければerrorになること' do
      template_seat_type = described_class.new(price: 10_000, master_seat_type: master_seat_type)
      expect(template_seat_type.valid?).to eq false
    end
  end
end
