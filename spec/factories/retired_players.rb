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
FactoryBot.define do
  factory :retired_player do
    player
    retired_at { Time.zone.now }
  end
end
