# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_titles
#
#  id               :bigint           not null, primary key
#  period           :integer
#  round            :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pf_hold_id       :string(255)
#  player_result_id :bigint           not null
#
# Indexes
#
#  index_hold_titles_on_player_result_id  (player_result_id)
#
# Foreign Keys
#
#  fk_rails_...  (player_result_id => player_results.id)
#
FactoryBot.define do
  factory :hold_title do
  end
end
