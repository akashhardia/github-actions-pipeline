# frozen_string_literal: true

# == Schema Information
#
# Table name: result_event_codes
#
#  id                    :bigint           not null, primary key
#  event_code            :string(255)
#  priority              :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  race_result_player_id :bigint           not null
#
# Indexes
#
#  index_result_event_codes_on_race_result_player_id  (race_result_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_result_player_id => race_result_players.id)
#
FactoryBot.define do
  factory :result_event_code do
    event_code { Faker::Number.number(digits: 6).to_s }
    priority { rand(2..10) }
  end
end
