# frozen_string_literal: true

# == Schema Information
#
# Table name: race_player_stats
#
#  id                   :bigint           not null, primary key
#  second_quinella_rate :float(24)
#  third_quinella_rate  :float(24)
#  winner_rate          :float(24)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  race_player_id       :bigint           not null
#
# Indexes
#
#  index_race_player_stats_on_race_player_id  (race_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_player_id => race_players.id)
#
require 'rails_helper'

RSpec.describe RacePlayerStat, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
