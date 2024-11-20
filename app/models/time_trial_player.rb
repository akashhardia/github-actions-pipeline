# frozen_string_literal: true

# == Schema Information
#
# Table name: time_trial_players
#
#  id                   :bigint           not null, primary key
#  entry_code           :string(255)
#  first_race_code      :string(255)
#  first_time           :decimal(6, 4)
#  gear                 :decimal(3, 2)
#  grade_code           :string(255)
#  pattern_code         :string(255)
#  race_code            :string(255)
#  ranking              :integer
#  repletion_code       :string(255)
#  second_time          :decimal(6, 4)
#  total_time           :decimal(6, 4)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  pf_player_id         :string(255)
#  time_trial_result_id :bigint           not null
#
# Indexes
#
#  index_time_trial_players_on_time_trial_result_id  (time_trial_result_id)
#
# Foreign Keys
#
#  fk_rails_...  (time_trial_result_id => time_trial_results.id)
#
class TimeTrialPlayer < ApplicationRecord
  belongs_to :time_trial_result
  has_one :time_trial_bike_info, dependent: :destroy
end
