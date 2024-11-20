# frozen_string_literal: true

# == Schema Information
#
# Table name: player_results
#
#  id                   :bigint           not null, primary key
#  consecutive_count    :integer
#  entry_count          :integer
#  first_count          :integer
#  first_place_count    :integer
#  outside_count        :integer
#  run_count            :integer
#  second_count         :integer
#  second_place_count   :integer
#  second_quinella_rate :float(24)
#  third_count          :integer
#  third_place_count    :integer
#  third_quinella_rate  :float(24)
#  winner_rate          :float(24)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  pf_player_id         :string(255)
#  player_id            :bigint
#
# Indexes
#
#  index_player_results_on_player_id  (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
FactoryBot.define do
  factory :player_result do
    player
    consecutive_count { 5 }
    entry_count { 5 }
    first_count { 5 }
    first_place_count { 5 }
    outside_count { 5 }
    run_count { 5 }
    second_count { 5 }
    second_place_count { 5 }
    second_quinella_rate { 3.12 }
    third_count { 5 }
    third_place_count { 5 }
    third_quinella_rate { 3.12 }
    winner_rate { 3.12 }
  end
end
