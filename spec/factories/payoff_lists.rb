# frozen_string_literal: true

# == Schema Information
#
# Table name: payoff_lists
#
#  id             :bigint           not null, primary key
#  payoff         :integer
#  payoff_type    :integer
#  tip1           :string(255)      not null
#  tip2           :string(255)
#  tip3           :string(255)
#  vote_type      :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_payoff_lists_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
FactoryBot.define do
  factory :payoff_list do
    payoff_type { 10 }
    vote_type { 10 }
    tip1 { 1 }
    tip2 { 2 }
    tip3 { 3 }
    payoff { 3000 }
  end
end
