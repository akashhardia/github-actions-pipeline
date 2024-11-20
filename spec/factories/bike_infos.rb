# frozen_string_literal: true

# == Schema Information
#
# Table name: bike_infos
#
#  id             :bigint           not null, primary key
#  frame_code     :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_player_id :bigint           not null
#
# Indexes
#
#  index_bike_infos_on_race_player_id  (race_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_player_id => race_players.id)
#
FactoryBot.define do
  factory :bike_info do
    race_player
  end
end
