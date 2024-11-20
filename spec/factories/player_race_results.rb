# frozen_string_literal: true

# == Schema Information
#
# Table name: player_race_results
#
#  id           :bigint           not null, primary key
#  daily_status :integer
#  event_code   :string(255)
#  event_date   :date
#  hold_daily   :integer
#  race_no      :integer
#  race_status  :integer
#  rank         :integer
#  time         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  entries_id   :string(255)
#  hold_id      :string(255)
#  player_id    :bigint           not null
#
# Indexes
#
#  index_player_race_results_on_player_id  (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
FactoryBot.define do
  factory :player_race_result do
    player
    sequence(:hold_id)
    event_date { '2020-10-12' }
    hold_daily { 5 }
    daily_status { 2 }
    entries_id { '1' }
    race_no { 5 }
    race_status { 1 }
    rank { 5 }
    time { 'mm:ss.MMMM' }
    event_code { 'A' }
  end
end
