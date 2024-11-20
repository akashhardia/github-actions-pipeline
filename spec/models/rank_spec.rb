# frozen_string_literal: true

# == Schema Information
#
# Table name: ranks
#
#  id             :bigint           not null, primary key
#  arrival_order  :integer          not null
#  car_number     :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_ranks_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
require 'rails_helper'

RSpec.describe Rank, type: :model do
  describe 'validationの確認' do
    it 'car_numberがなければerrorになること' do
      payoff_list = build(:rank, car_number: nil)
      expect(payoff_list.valid?).to eq false
      expect(payoff_list.errors.messages[:car_number]).to eq(['を入力してください'])
    end

    it 'arrival_orderがなければerrorになること' do
      payoff_list = build(:rank, arrival_order: nil)
      expect(payoff_list.valid?).to eq false
      expect(payoff_list.errors.messages[:arrival_order]).to eq(['を入力してください'])
    end
  end
end
