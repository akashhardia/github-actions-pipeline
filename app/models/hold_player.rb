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
class HoldPlayer < ApplicationRecord
  belongs_to :hold
  belongs_to :player
  belongs_to :last_hold_player, class_name: 'HoldPlayer', optional: true
  belongs_to :last_ranked_hold_player, class_name: 'HoldPlayer', optional: true
  has_one :mediated_player, dependent: :destroy, class_name: 'MediatedPlayer'
  has_many :hold_player_results, dependent: :destroy
  has_many :race_result_players, through: :hold_player_results
end
