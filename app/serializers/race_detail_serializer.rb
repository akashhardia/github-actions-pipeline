# frozen_string_literal: true

# == Schema Information
#
# Table name: race_details
#
#  id              :bigint           not null, primary key
#  bike_count      :string(255)
#  close_time      :datetime
#  daily_branch    :integer
#  details_code    :string(255)
#  entry_code      :string(255)
#  event_code      :string(255)
#  first_day       :date
#  first_race_code :string(255)
#  grade_code      :string(255)
#  hold_daily      :integer
#  hold_day        :string(255)
#  hold_id_daily   :integer          not null
#  laps_count      :integer
#  pattern_code    :string(255)
#  post_time       :string(255)
#  race_code       :string(255)
#  race_distance   :integer
#  race_status     :string(255)
#  repletion_code  :string(255)
#  time_zone_code  :integer
#  track_code      :string(255)
#  type_code       :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  entries_id      :string(255)      not null
#  pf_hold_id      :string(255)      not null
#  race_id         :bigint           not null
#
# Indexes
#
#  index_race_details_on_race_id  (race_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_id => races.id)
#
class RaceDetailSerializer < ActiveModel::Serializer
  has_many :race_players
  has_many :vote_infos
  has_many :payoff_lists
  has_many :ranks
  attributes :id, :pf_hold_id, :track_code, :hold_day, :race_status,
             :race_distance, :laps_count, :race_code, :first_race_code,
             :entry_code, :type_code, :event_code, :details_code
end
