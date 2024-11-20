# frozen_string_literal: true

# == Schema Information
#
# Table name: result_event_codes
#
#  id                    :bigint           not null, primary key
#  event_code            :string(255)
#  priority              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  race_result_player_id :bigint           not null
#
# Indexes
#
#  index_result_event_codes_on_race_result_player_id  (race_result_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_result_player_id => race_result_players.id)
#
require 'rails_helper'

RSpec.describe ResultEventCode, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
