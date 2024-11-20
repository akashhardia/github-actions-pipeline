# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_areas
#
#  id           :bigint           not null, primary key
#  area_code    :string(255)      not null
#  area_name    :string(255)      not null
#  position     :string(255)
#  sub_code     :string(255)
#  sub_position :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'rails_helper'

RSpec.describe MasterSeatArea, type: :model do
  describe 'validationの確認' do
    it 'areaがなければerrorになること' do
      master_seat_area = described_class.new
      expect(master_seat_area.valid?).to eq false
    end
  end
end
