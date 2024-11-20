# frozen_string_literal: true

# == Schema Information
#
# Table name: retired_players
#
#  id         :bigint           not null, primary key
#  retired_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  player_id  :bigint           not null
#
# Indexes
#
#  index_retired_players_on_player_id  (player_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
require 'rails_helper'

RSpec.describe RetiredPlayer, type: :model do
  describe 'validationの確認' do
    it 'playerがなければerrorになること' do
      retired_player = build(:retired_player, player: nil)
      expect(retired_player.valid?).to eq false
      expect(retired_player.errors.messages[:player]).to eq(['を入力してください'])
    end

    it 'playerが重複していればerrorになること' do
      retired_player = create(:retired_player)
      dup_retired_player = build(:retired_player, player: retired_player.player)
      expect(dup_retired_player.valid?).to eq false
      expect(dup_retired_player.errors.messages[:player_id]).to eq(['はすでに存在します'])
    end

    it 'retired_atがなければerrorになること' do
      retired_player = build(:retired_player, retired_at: nil)
      expect(retired_player.valid?).to eq false
      expect(retired_player.errors.messages[:retired_at]).to eq(['を入力してください'])
    end
  end
end
