# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_dailies
#
#  id            :bigint           not null, primary key
#  daily_branch  :integer          not null
#  daily_status  :integer          not null
#  event_date    :date             not null
#  hold_daily    :integer          not null
#  hold_id_daily :integer          not null
#  program_count :integer
#  race_count    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_id       :bigint           not null
#
# Indexes
#
#  index_hold_dailies_on_hold_id  (hold_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#
FactoryBot.define do
  factory :hold_daily do
    hold { create(:hold) }
    hold_id_daily { 1 }
    event_date { Time.zone.now }
    hold_daily { 1 }
    daily_branch { 1 }
    program_count { 1 }
    race_count { 1 }
    daily_status { 1 }

    trait :after_event do
      event_date { Time.zone.now - 1.day }
    end

    trait :today_event do
      event_date { Time.zone.now }
    end

    trait :before_event_one_day do
      event_date { Time.zone.now + 1.day }
    end

    trait :before_event_over_one_day do
      event_date { Time.zone.now + 2.days }
    end

    trait :with_final_race do
      after(:create) do |hold_daily|
        hold_daily_schedule = create(:hold_daily_schedule, hold_daily: hold_daily)
        race = create(:race, event_code: '3', hold_daily_schedule: hold_daily_schedule, free_text: (0...8).map { ('a'..'z').to_a[rand(26)] }.join)
        race_detail = create(:race_detail, hold_day: '20210528', race: race)
        create(:race_player, :with_player, race_detail: race_detail)
      end
    end

    trait :with_race_result do
      after(:create) do |hold_daily|
        hold_daily_schedule = create(:hold_daily_schedule, hold_daily: hold_daily)
        race = create(:race, hold_daily_schedule: hold_daily_schedule, free_text: (0...8).map { ('a'..'z').to_a[rand(26)] }.join)
        race_detail = create(:race_detail, hold_day: '20210528', race: race, first_day: Time.zone.today)
        create(:race_result, race_stts: '15', race_detail: race_detail)
        create(:race_player, :with_player, race_detail: race_detail)
      end
    end
  end
end
