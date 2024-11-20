# frozen_string_literal: true

# == Schema Information
#
# Table name: races
#
#  id                     :bigint           not null, primary key
#  details_code           :string(255)
#  entry_code             :string(255)
#  event_code             :string(255)
#  first_race_code        :string(255)
#  free_text              :text(65535)
#  lap_count              :integer          not null
#  pattern_code           :string(255)
#  post_start_time        :datetime         not null
#  post_time              :string(255)
#  program_no             :integer          not null
#  race_code              :string(255)      not null
#  race_distance          :integer          not null
#  race_no                :integer          not null
#  time_zone_code         :integer
#  type_code              :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  entries_id             :string(255)
#  hold_daily_schedule_id :bigint           not null
#  interview_movie_yt_id  :string(255)
#  race_movie_yt_id       :string(255)
#
# Indexes
#
#  index_races_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#
FactoryBot.define do
  factory :race do
    lap_count { 1 }
    post_start_time { Time.zone.now }
    sequence(:program_no)
    race_code { 1 }
    race_distance { 1000 }
    sequence(:race_no)
    hold_daily_schedule

    trait :with_race_detail do
      after(:create) do |race|
        player_original_info = create(:player_original_info)
        player = player_original_info.player
        hold = race.hold_daily_schedule.hold_daily.hold
        create(:hold_player, hold: hold, player_id: player.id)
        time_trial_result = create(:time_trial_result, hold_id: hold.id)
        race_detail = create(:race_detail, race_id: race.id, hold_day: '20210101', pf_hold_id: hold.pf_hold_id)
        race_result = create(:race_result, race_detail_id: race_detail.id, race_time: 1.1)
        create(:race_result_player, race_result_id: race_result.id, rank: 3, pf_player_id: player.pf_player_id)
        odds_info = create(:odds_info, race_detail_id: race_detail.id)
        odds_list = create(:odds_list, odds_info_id: odds_info.id, vote_type: 10)
        race_player = create(:race_player, pf_player_id: player.pf_player_id, race_detail_id: race_detail.id, bike_no: 5)
        create(:time_trial_player, time_trial_result_id: time_trial_result.id, pf_player_id: race_player.pf_player_id)
        create(:odds_detail, odds_list_id: odds_list.id, odds_val: 1.1, tip1: race_player.bike_no)
        create(:payoff_list, race_detail_id: race_detail.id)
      end
    end

    trait :with_bike_no_nil_race_player do
      after(:create) do |race|
        player_original_info = create(:player_original_info)
        player = player_original_info.player
        create(:hold_player, hold: race.hold_daily_schedule.hold_daily.hold, player_id: player.id)
        time_trial_result = create(:time_trial_result, hold_id: race.hold_daily_schedule.hold_daily.hold.id)
        race_detail = create(:race_detail, race_id: race.id, hold_day: '20210101')
        race_result = create(:race_result, race_detail_id: race_detail.id, race_time: 1.1)
        create(:race_result_player, race_result_id: race_result.id, rank: 3, pf_player_id: player.pf_player_id)
        odds_info = create(:odds_info, race_detail_id: race_detail.id)
        odds_list = create(:odds_list, odds_info_id: odds_info.id, vote_type: 10)
        race_player = create(:race_player, pf_player_id: player.pf_player_id, race_detail_id: race_detail.id, bike_no: nil)
        create(:time_trial_player, time_trial_result_id: time_trial_result.id, pf_player_id: race_player.pf_player_id)
        create(:odds_detail, odds_list_id: odds_list.id, odds_val: 1.1, tip1: 'test')
        create(:payoff_list, race_detail_id: race_detail.id)
      end
    end

    trait :with_payoff_type_nil do
      after(:create) do |race|
        player_original_info = create(:player_original_info)
        player = player_original_info.player
        create(:hold_player, hold: race.hold_daily_schedule.hold_daily.hold, player_id: player.id)
        time_trial_result = create(:time_trial_result, hold_id: race.hold_daily_schedule.hold_daily.hold.id)
        race_detail = create(:race_detail, race_id: race.id, hold_day: '20210101')
        race_result = create(:race_result, race_detail_id: race_detail.id, race_time: 1.1)
        create(:race_result_player, race_result_id: race_result.id, rank: 3, pf_player_id: player.pf_player_id)
        odds_info = create(:odds_info, race_detail_id: race_detail.id)
        odds_list = create(:odds_list, odds_info_id: odds_info.id, vote_type: 10)
        race_player = create(:race_player, pf_player_id: player.pf_player_id, race_detail_id: race_detail.id, bike_no: 5)
        create(:time_trial_player, time_trial_result_id: time_trial_result.id, pf_player_id: race_player.pf_player_id)
        create(:odds_detail, odds_list_id: odds_list.id, odds_val: 1.1, tip1: race_player.bike_no)
        create(:payoff_list, payoff_type: nil, race_detail_id: race_detail.id)
      end
    end

    trait :with_vote_type_nil do
      after(:create) do |race|
        player_original_info = create(:player_original_info)
        player = player_original_info.player
        create(:hold_player, hold: race.hold_daily_schedule.hold_daily.hold, player_id: player.id)
        time_trial_result = create(:time_trial_result, hold_id: race.hold_daily_schedule.hold_daily.hold.id)
        race_detail = create(:race_detail, race_id: race.id, hold_day: '20210101')
        race_result = create(:race_result, race_detail_id: race_detail.id, race_time: 1.1)
        create(:race_result_player, race_result_id: race_result.id, rank: 3, pf_player_id: player.pf_player_id)
        odds_info = create(:odds_info, race_detail_id: race_detail.id)
        odds_list = create(:odds_list, odds_info_id: odds_info.id, vote_type: 10)
        race_player = create(:race_player, pf_player_id: player.pf_player_id, race_detail_id: race_detail.id, bike_no: 5)
        create(:time_trial_player, time_trial_result_id: time_trial_result.id, pf_player_id: race_player.pf_player_id)
        create(:odds_detail, odds_list_id: odds_list.id, odds_val: 1.1, tip1: race_player.bike_no)
        create(:payoff_list, vote_type: nil, race_detail_id: race_detail.id)
      end
    end
  end
end
