# frozen_string_literal: true

require 'rails_helper'

describe LastHoldPlayerResolver do
  describe '.resolve' do
    subject(:resolve) { described_class.resolve(hold_id: hold_player.hold.id, player_id: hold_player.player.id) }

    let(:hold_player) { create(:hold_player, hold: hold, player: player) }
    let(:hold) { create(:hold) }
    let(:player) { create(:player) }

    context '開催に紐づくHoldPlayerが存在しない' do
      before do
        hold_player.update!(hold: create(:hold))
      end

      it '結果: nil を返すこと' do
        expect(resolve).to eq nil
      end
    end

    context 'HoldPlayer.last_hold_player_id がnilではない' do
      let(:last_hold_player_id) { HoldPlayer.pluck(:id).sample }

      before do
        create_list(:hold_player, 10)
        hold_player.update!(last_hold_player_id: last_hold_player_id)
      end

      it '結果: last_ranked_hold_player_id がnilではないこと' do
        expect(resolve).not_to eq nil
      end

      it '結果: last_ranked_hold_player_id を返すこと' do
        expect(resolve).to eq last_hold_player_id
      end
    end

    context 'HoldPlayerよりも過去のHoldPlayerがある' do
      let(:last_ranked_hold_player_id) { nil }
      let(:last_hold_player) { create(:hold_player, :with_race_result, player: player) }

      before do
        hold.update!(first_day: rand(0..30).days.after)
        last_hold_player.hold.update!(first_day: hold.first_day - 7.days)

        old_hold_player = create(:hold_player, :with_race_result, player: player)
        old_hold_player.hold.update!(first_day: hold.first_day - 8.days)

        other_hold_player = create(:hold_player, :with_race_result)
        other_hold_player.hold.update!(first_day: hold.first_day - 6.days)
      end

      it '結果: last_hold_player_id がnilではないこと' do
        expect(resolve).not_to eq nil
      end

      it '結果: 過去のHoldPlayerのidを返すこと' do
        expect(resolve).to eq last_hold_player.id
      end

      it '結果: last_hold_player_id が更新されること' do
        expect { resolve }.to change { hold_player.reload.last_hold_player_id }.from(nil).to(last_hold_player.id)
      end
    end

    context 'HoldPlayerよりも過去のHoldPlayerがない' do
      let(:last_ranked_hold_player_id) { nil }

      before do
        hold.update!(first_day: rand(0..30).days.after)
        next_hold_player = create(:hold_player, :with_race_result, player: player)
        next_hold_player.hold.update!(first_day: hold.first_day + rand(2..30).days)

        other_hold_player = create(:hold_player, :with_race_result)
        other_hold_player.hold.update!(first_day: hold.first_day - rand(2..30).days)
      end

      it '結果: nil を返すこと' do
        expect(resolve).to eq nil
      end

      it '結果: last_ranked_hold_player_id が更新されないこと' do
        expect { resolve }.not_to(change { hold_player.reload.last_hold_player_id })
      end
    end
  end
end
