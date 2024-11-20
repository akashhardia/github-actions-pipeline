# frozen_string_literal: true

# == Schema Information
#
# Table name: time_trial_bike_infos
#
#  id                   :bigint           not null, primary key
#  frame_code           :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  time_trial_player_id :bigint           not null
#
# Indexes
#
#  index_time_trial_bike_infos_on_time_trial_player_id  (time_trial_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (time_trial_player_id => time_trial_players.id)
#
class TimeTrialBikeInfo < ApplicationRecord
  belongs_to :time_trial_player
  has_one :time_trial_front_wheel_info, dependent: :destroy
  has_one :time_trial_rear_wheel_info, dependent: :destroy
end
