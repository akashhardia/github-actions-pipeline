# frozen_string_literal: true

# == Schema Information
#
# Table name: mediated_players
#
#  id              :bigint           not null, primary key
#  add_day         :string(255)
#  add_issue_code  :string(255)
#  change_code     :string(255)
#  entry_code      :string(255)
#  first_race_code :string(255)
#  grade_code      :string(255)
#  issue_code      :string(255)
#  join_code       :string(255)
#  miss_day        :string(255)
#  pattern_code    :string(255)
#  race_code       :string(255)
#  regist_num      :integer
#  repletion_code  :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  add_issue_id    :string(255)
#  hold_player_id  :bigint
#  pf_player_id    :string(255)
#
# Indexes
#
#  index_mediated_players_on_hold_player_id  (hold_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_player_id => hold_players.id)
#
require 'rails_helper'

RSpec.describe MediatedPlayer, type: :model do
  describe '#pf_250_regist_id' do
    subject(:pf_250_regist_id) { mediated_player.pf_250_regist_id }

    let(:original_info) { create(:player_original_info, pf_250_regist_id: regist_id) }
    let(:hold_player) { create(:hold_player, player: original_info.player) }
    let(:mediated_player) { create(:mediated_player, hold_player: hold_player) }

    context 'pf_250_regist_idがある場合' do
      let(:regist_id) { '10' }

      it '想定している値が返ること' do
        expect(pf_250_regist_id).to eq('10')
      end
    end

    context 'pf_250_regist_idがnilの場合' do
      let(:regist_id) { nil }

      it '想定している値が返ること' do
        expect(pf_250_regist_id).to eq(nil)
      end
    end
  end

  describe '#full_name' do
    subject(:full_name) { mediated_player.full_name }

    let(:original_info) { create(:player_original_info, last_name_jp: last_name, first_name_jp: first_name) }
    let(:hold_player) { create(:hold_player, player: original_info.player) }
    let(:mediated_player) { create(:mediated_player, hold_player: hold_player) }

    context 'last_nameとfirst_nameが半角スペースで連結されて返されること' do
      let(:last_name) { '田中' }
      let(:first_name) { '太郎' }

      it '指定されたfieldの値しかシリアライズされないこと' do
        expect(full_name).to eq('田中 太郎')
      end
    end

    context 'last_nameとfirst_nameがない場合は半角スペースのみで返されること' do
      let(:last_name) { '' }
      let(:first_name) { '' }

      it '指定されたfieldの値しかシリアライズされないこと' do
        expect(full_name).to eq(' ')
      end
    end
  end
end
