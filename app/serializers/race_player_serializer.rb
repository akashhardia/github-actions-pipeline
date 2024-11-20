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
class RacePlayerSerializer < ActiveModel::Serializer
  has_one :bike_info
  attributes :id, :bracket_no, :bike_no, :player_id, :pf_player_id, :name_jp, :gear, :miss, :start_position,
             :created_at, :updated_at

  def name_jp
    player&.name_jp
  end

  def player_id
    player&.id
  end

  private

  def player
    @player ||= Player.find_by(pf_player_id: object.pf_player_id)
  end
end
