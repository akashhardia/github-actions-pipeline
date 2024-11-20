# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_player_results
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  hold_player_id        :bigint           not null
#  race_result_player_id :bigint           not null
#
# Indexes
#
#  index_hold_player_results_on_hold_player_id         (hold_player_id)
#  index_hold_player_results_on_race_result_player_id  (race_result_player_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (hold_player_id => hold_players.id)
#  fk_rails_...  (race_result_player_id => race_result_players.id)
#
FactoryBot.define do
  factory :hold_player_result do
  end
end
