# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_type_options
#
#  id                           :bigint           not null, primary key
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  seat_type_id                 :bigint           not null
#  template_seat_type_option_id :bigint           not null
#
# Indexes
#
#  index_seat_type_options_on_seat_type_id                  (seat_type_id)
#  index_seat_type_options_on_template_seat_type_option_id  (template_seat_type_option_id)
#
# Foreign Keys
#
#  fk_rails_...  (seat_type_id => seat_types.id)
#  fk_rails_...  (template_seat_type_option_id => template_seat_type_options.id)
#
require 'rails_helper'

RSpec.describe SeatTypeOption, type: :model do
  describe 'validate確認' do
    let(:template_seat_type_option) { create(:template_seat_type_option) }
    let(:seat_type) { create(:seat_type) }

    it 'seat_typeがなければerrorになること' do
      seat_type_option = described_class.new(template_seat_type_option: template_seat_type_option)
      expect(seat_type_option.valid?).to eq false
    end

    it 'template_seat_type_optionがなければerrorになること' do
      seat_type_option = described_class.new(seat_type: seat_type)
      expect(seat_type_option.valid?).to eq false
    end
  end
end
