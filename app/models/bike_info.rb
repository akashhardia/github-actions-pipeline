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
class BikeInfo < ApplicationRecord
  belongs_to :race_player
  has_one :front_wheel_info, dependent: :destroy
  has_one :rear_wheel_info, dependent: :destroy
end
