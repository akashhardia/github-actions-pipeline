# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_details
#
#  id           :bigint           not null, primary key
#  odds_max_val :decimal(6, 1)
#  odds_val     :decimal(6, 1)    not null
#  tip1         :string(255)      not null
#  tip2         :string(255)
#  tip3         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  odds_list_id :bigint           not null
#
# Indexes
#
#  index_odds_details_on_odds_list_id  (odds_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (odds_list_id => odds_lists.id)
#
require 'rails_helper'

RSpec.describe OddsDetail, type: :model do
  describe 'validationの確認' do
    it 'odds_valがなければerrorになること' do
      odds_detail = build(:odds_detail, tip1: 1, odds_val: nil)
      expect(odds_detail.valid?).to eq false
      expect(odds_detail.errors.messages[:odds_val]).to eq(['を入力してください'])
    end

    it 'tip1がなければerrorになること' do
      odds_detail = build(:odds_detail, tip1: nil, odds_val: 5.1)
      expect(odds_detail.valid?).to eq false
      expect(odds_detail.errors.messages[:tip1]).to eq(['を入力してください'])
    end
  end
end
