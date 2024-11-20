# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_infos
#
#  id             :bigint           not null, primary key
#  fixed          :boolean          not null
#  odds_time      :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  entries_id     :string(255)      not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_odds_infos_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
require 'rails_helper'

RSpec.describe OddsInfo, type: :model do
  describe 'validationの確認' do
    it 'fixedがなければerrorになること' do
      odds_info = build(:odds_info, fixed: nil)
      expect(odds_info.valid?).to eq false
      expect(odds_info.errors.messages[:fixed]).to eq(['は一覧にありません'])
    end

    it 'odds_timeがなければerrorになること' do
      odds_info = build(:odds_info, odds_time: nil)
      expect(odds_info.valid?).to eq false
      expect(odds_info.errors.messages[:odds_time]).to eq(['を入力してください'])
    end

    it 'entries_idがなければerrorになること' do
      odds_info = build(:odds_info, entries_id: nil)
      expect(odds_info.valid?).to eq false
      expect(odds_info.errors.messages[:entries_id]).to eq(['を入力してください'])
    end
  end
end
