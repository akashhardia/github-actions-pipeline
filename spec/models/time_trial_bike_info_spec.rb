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
require 'rails_helper'

RSpec.describe TimeTrialBikeInfo, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
