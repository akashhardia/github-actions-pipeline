# frozen_string_literal: true

# == Schema Information
#
# Table name: race_players
#
#  id             :bigint           not null, primary key
#  bike_no        :integer
#  bracket_no     :integer
#  gear           :decimal(3, 2)
#  miss           :boolean          not null
#  start_position :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  pf_player_id   :string(255)
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_race_players_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
class RacePlayer < ApplicationRecord
  belongs_to :race_detail
  has_one :bike_info, dependent: :destroy
  has_one :race_player_stat, dependent: :destroy

  validates :miss, inclusion: { in: [true, false] }

  scope :mt_api_race_player_scope, -> do
    where.not(bike_no: nil)
  end

  def result_time
    race_detail.race_result_players.find_by(pf_player_id: pf_player_id)&.last_lap.to_f
  end

  def result_rank
    race_detail.race_result_players.find_by(pf_player_id: pf_player_id)&.rank
  end

  def result_difference_code
    race_detail.race_result_players.find_by(pf_player_id: pf_player_id)&.difference_code
  end
end
