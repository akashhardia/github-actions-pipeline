# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe MasterSeatType, type: :model do
  describe 'validationの確認' do
    it 'nameがなければerrorになること' do
      master_seat_type = described_class.new
      expect(master_seat_type.valid?).to eq false
    end
  end
end
