# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_players
#
#  id                         :bigint           not null, primary key
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  hold_id                    :bigint
#  last_hold_player_id        :bigint
#  last_ranked_hold_player_id :bigint
#  player_id                  :bigint
#
# Indexes
#
#  index_hold_players_on_hold_id                     (hold_id)
#  index_hold_players_on_last_hold_player_id         (last_hold_player_id)
#  index_hold_players_on_last_ranked_hold_player_id  (last_ranked_hold_player_id)
#  index_hold_players_on_player_id                   (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#  fk_rails_...  (last_hold_player_id => hold_players.id)
#  fk_rails_...  (last_ranked_hold_player_id => hold_players.id)
#  fk_rails_...  (player_id => players.id)
#
require 'rails_helper'

RSpec.describe HoldPlayer, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
