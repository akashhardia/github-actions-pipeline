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
FactoryBot.define do
  factory :mediated_player do
    hold_player
    entry_code { 6 }
    first_race_code { 'C' }
    grade_code { '0' }
    issue_code { '100' }
    race_code { '3' }
    regist_num { 14697 }
    repletion_code { '5' }
    pf_player_id { hold_player.player.pf_player_id }
  end
end
