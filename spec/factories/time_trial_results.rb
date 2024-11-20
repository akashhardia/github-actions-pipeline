# frozen_string_literal: true

# == Schema Information
#
# Table name: time_trial_results
#
#  id         :bigint           not null, primary key
#  confirm    :boolean
#  players    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  hold_id    :bigint           not null
#  pf_hold_id :string(255)      not null
#
# Indexes
#
#  index_time_trial_results_on_hold_id  (hold_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#
FactoryBot.define do
  factory :time_trial_result do
    hold
    pf_hold_id { hold.pf_hold_id }
  end
end
