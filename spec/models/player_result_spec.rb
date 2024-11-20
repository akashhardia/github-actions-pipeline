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
require 'rails_helper'

RSpec.describe PlayerResult, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
