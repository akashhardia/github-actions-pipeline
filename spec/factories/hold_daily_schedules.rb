# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_daily_schedules
#
#  id            :bigint           not null, primary key
#  daily_no      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_daily_id :bigint           not null
#
# Indexes
#
#  index_hold_daily_schedules_on_hold_daily_id  (hold_daily_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_id => hold_dailies.id)
#
FactoryBot.define do
  factory :hold_daily_schedule do
    hold_daily
    daily_no { 0 }

    trait :with_race do
      after(:create) do |hold_daily_schedule|
        create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST.sample, hold_daily_schedule: hold_daily_schedule)
      end
    end
  end
end
