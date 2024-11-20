# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_details
#
#  id           :bigint           not null, primary key
#  odds_max_val :decimal(6, 1)
#  odds_val     :decimal(6, 1)    not null
#  tip1         :string(255)      not null
#  tip2         :string(255)
#  tip3         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  odds_list_id :bigint           not null
#
# Indexes
#
#  index_odds_details_on_odds_list_id  (odds_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (odds_list_id => odds_lists.id)
#
FactoryBot.define do
  factory :odds_detail do
    odds_list
    odds_max_val { 10.1 }
    odds_val { 5.1 }
    tip1 { 1 }
    tip2 { 2 }
    tip3 { 3 }
  end
end
