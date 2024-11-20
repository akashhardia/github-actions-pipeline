# frozen_string_literal: true

# == Schema Information
#
# Table name: holds
#
#  id                 :bigint           not null, primary key
#  audience           :boolean
#  first_day          :date             not null
#  first_day_manually :date
#  girl               :boolean
#  grade_code         :string(255)      not null
#  hold_days          :integer          not null
#  hold_name_en       :string(255)
#  hold_name_jp       :string(255)
#  hold_status        :integer
#  period             :integer
#  promoter           :string(255)
#  promoter_code      :string(255)      not null
#  promoter_section   :integer
#  promoter_times     :integer
#  promoter_year      :integer
#  purpose_code       :string(255)      not null
#  repletion_code     :string(255)
#  round              :integer
#  season             :string(255)
#  time_zone          :integer
#  title_en           :string(255)
#  title_jp           :string(255)
#  track_code         :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pf_hold_id         :string(255)      not null
#  tt_movie_yt_id     :string(255)
#
# Indexes
#
#  index_holds_on_hold_status  (hold_status)
#  index_holds_on_pf_hold_id   (pf_hold_id) UNIQUE
#
FactoryBot.define do
  factory :hold do
    sequence(:pf_hold_id, '100')
    track_code { 'MyString' }
    first_day { '2020-10-07' }
    hold_days { 1 }
    grade_code { 'MyString' }
    purpose_code { 'MyString' }
    repletion_code { 'MyString' }
    hold_name_jp { 'MyString' }
    hold_name_en { 'MyString' }
    hold_status { 1 }
    period { [1, 2, 3, 4, 101, 201, 301].sample }
    promoter_code { 'MyString' }
    promoter_year { 1 }
    promoter_times { 1 }
    promoter_section { 1 }
    tt_movie_yt_id { 'MyString' }
    round { 1 }

    trait :with_mediated_players do
      after(:create) do |hold|
        player = create(:player, :with_original_info)
        hold_player = create(:hold_player, hold: hold, player: player)
        create(:hold_daily, event_date: Time.zone.now, hold: hold)
        create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id)
      end
    end

    trait :with_player_detail do
      after(:create) do |hold|
        player = create(:player, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join)
        hold_player = create(:hold_player, hold: hold, player: player)
        hold_daily = create(:hold_daily, hold: hold)
        hold_daily_schedule = create(:hold_daily_schedule, hold_daily_id: hold_daily.id)
        race = create(:race, hold_daily_schedule_id: hold_daily_schedule.id)
        race_detail = create(:race_detail, race_id: race.id)
        race_result = create(:race_result, race_detail_id: race_detail.id)
        create(:race_result_player, race_result_id: race_result.id, pf_player_id: player.pf_player_id)

        create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id)
        create(:player_result, player_id: player.id, pf_player_id: player.pf_player_id)
        create(:player_original_info, player_id: player.id, speed: rand(1..100), stamina: rand(1..100), power: rand(1..100),
                                      technique: rand(1..100), mental: rand(1..100), evaluation: rand(1..100),
                                      last_name_en: player.name_en, first_name_en: player.name_en)
      end
    end
  end
end
