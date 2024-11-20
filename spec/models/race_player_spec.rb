# frozen_string_literal: true

# == Schema Information
#
# Table name: race_players
#
#  id             :bigint           not null, primary key
#  bike_no        :integer
#  bracket_no     :integer
#  gear           :decimal(3, 2)
#  miss           :boolean          not null
#  start_position :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  pf_player_id   :string(255)
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_race_players_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
require 'rails_helper'

RSpec.describe RacePlayer, type: :model do
  describe 'バリデーション: 必須チェック' do
    it 'missがtrue,false以外を設定するとバリデーションエラーになること' do
      race_player = build(:race_player)
      race_player.miss = nil
      expect(race_player.invalid?).to be true
      expect(race_player.errors.details[:miss][0][:error]).to eq(:inclusion)
    end
  end

  describe 'インスタンスメソッド' do
    let(:race_player) { create(:race_player, :with_player) }
    let(:race_result) { create(:race_result, race_detail_id: race_player.race_detail.id) }
    let(:race_result_player) { create(:race_result_player, race_result_id: race_result.id, pf_player_id: race_player.pf_player_id, last_lap: 1.012e1, rank: 1, difference_code: '0000') }

    before do
      race_result_player
    end

    it '#result_time' do
      expect(race_player.result_time).to eq(1.012e1)
    end

    it '#result_rank' do
      expect(race_player.result_rank).to eq(1)
    end

    it '#result_difference_code' do
      expect(race_player.result_difference_code).to eq('0000')
    end
  end
end
