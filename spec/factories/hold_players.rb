# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_players
#
#  id                         :bigint           not null, primary key
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  hold_id                    :bigint
#  last_hold_player_id        :bigint
#  last_ranked_hold_player_id :bigint
#  player_id                  :bigint
#
# Indexes
#
#  index_hold_players_on_hold_id                     (hold_id)
#  index_hold_players_on_last_hold_player_id         (last_hold_player_id)
#  index_hold_players_on_last_ranked_hold_player_id  (last_ranked_hold_player_id)
#  index_hold_players_on_player_id                   (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#  fk_rails_...  (last_hold_player_id => hold_players.id)
#  fk_rails_...  (last_ranked_hold_player_id => hold_players.id)
#  fk_rails_...  (player_id => players.id)
#
FactoryBot.define do
  factory :hold_player do
    hold
    player

    trait :with_race_result do
      after(:create) do |hold_player|
        hold_daily = create(:hold_daily, hold: hold_player.hold)
        hold_daily_schedule = create(:hold_daily_schedule, hold_daily: hold_daily)
        race = create(:race, hold_daily_schedule: hold_daily_schedule)
        race_detail = create(:race_detail, race: race)
        race_result = create(:race_result, race_detail: race_detail)
        race_result_player = create(:race_result_player, race_result: race_result, pf_player_id: hold_player.player.pf_player_id, rank: rand(0..40))
        create(:hold_player_result, hold_player: hold_player, race_result_player: race_result_player)
      end
    end
  end
end
