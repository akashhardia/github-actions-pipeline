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
class MediatedPlayer < ApplicationRecord
  ADDITIONAL_CODE = %w[300 410 420].freeze

  belongs_to :hold_player

  scope :active_pf_250_regist_id_and_full_name_en, -> do
    return if blank?

    includes(hold_player: { player: :player_original_info }).where.not(player_original_info: { pf_250_regist_id: nil })
                                                            .where.not(player_original_info: { first_name_en: nil })
                                                            .where.not(player_original_info: { last_name_en: nil })
  end

  delegate :player, to: :hold_player

  def pf_250_regist_id
    player.player_original_info&.pf_250_regist_id
  end

  # player_original_infoがない、またはlast_name_jp,first_name_jp両方ない場合は半角スペースを返す
  def full_name
    original_info = player.player_original_info
    "#{original_info&.last_name_jp} #{original_info&.first_name_jp}"
  end
end
