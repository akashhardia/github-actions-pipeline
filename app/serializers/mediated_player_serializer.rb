# frozen_string_literal: true

# == Schema Information
#
# Table name: mediated_players
#
#  id              :bigint           not null, primary key
#  add_day         :string(255)
#  add_issue_code  :string(255)
#  change_code     :string(255)
#  entry_code      :string(255)
#  first_race_code :string(255)
#  grade_code      :string(255)
#  issue_code      :string(255)
#  join_code       :string(255)
#  miss_day        :string(255)
#  pattern_code    :string(255)
#  race_code       :string(255)
#  regist_num      :integer
#  repletion_code  :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  add_issue_id    :string(255)
#  hold_player_id  :bigint
#  pf_player_id    :string(255)
#
# Indexes
#
#  index_mediated_players_on_hold_player_id  (hold_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_player_id => hold_players.id)
#
class MediatedPlayerSerializer < ActiveModel::Serializer
  attributes :id, :player_id, :pf_player_id, :regist_num, :issue_code, :name_jp, :country_code, :area_code, :created_at, :updated_at

  def name_jp
    object.player.name_jp
  end

  def country_code
    object.player.player_original_info&.free2
  end

  def area_code
    object.player.area_code
  end

  def player_id
    object.player.id
  end
end
