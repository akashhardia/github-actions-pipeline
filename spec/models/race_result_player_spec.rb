# frozen_string_literal: true

# == Schema Information
#
# Table name: race_result_players
#
#  id              :bigint           not null, primary key
#  back_class      :boolean
#  bike_no         :integer
#  difference_code :string(255)
#  home_class      :boolean
#  incoming        :integer
#  last_lap        :decimal(6, 4)
#  point           :integer
#  rank            :integer
#  start_position  :integer
#  trick_code      :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  pf_player_id    :string(255)
#  race_result_id  :bigint           not null
#
# Indexes
#
#  index_race_result_players_on_pf_player_id    (pf_player_id)
#  index_race_result_players_on_race_result_id  (race_result_id)
#  index_race_result_players_on_rank            (rank)
#
# Foreign Keys
#
#  fk_rails_...  (race_result_id => race_results.id)
#
require 'rails_helper'

RSpec.describe RaceResultPlayer, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
