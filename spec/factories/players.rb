# frozen_string_literal: true

# == Schema Information
#
# Table name: players
#
#  id                :bigint           not null, primary key
#  area_code         :string(255)
#  birthday          :date
#  catchphrase       :string(255)
#  chest             :decimal(4, 1)
#  country_code      :string(255)
#  current_rank_code :string(255)
#  dash              :decimal(4, 2)
#  delete_day        :date
#  duration          :decimal(4, 2)
#  gender_code       :integer
#  graduate          :integer
#  height            :decimal(4, 1)
#  keirin_delete     :date
#  keirin_expiration :date
#  keirin_regist     :date
#  keirin_update     :date
#  lap_1000          :string(255)
#  lap_200           :string(255)
#  lap_400           :string(255)
#  leftgrip          :decimal(3, 1)
#  max_speed         :decimal(4, 2)
#  middle_delete     :date
#  middle_expiration :date
#  middle_regist     :date
#  middle_update     :date
#  name_en           :string(255)
#  name_jp           :string(255)
#  next_rank_code    :string(255)
#  player_class      :integer
#  regist_day        :date
#  regist_num        :integer
#  rightgrip         :decimal(3, 1)
#  spine             :decimal(5, 1)
#  thigh             :decimal(4, 1)
#  vital             :decimal(5, 1)
#  weight            :decimal(4, 1)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pf_player_id      :string(255)
#
# Indexes
#
#  index_players_on_pf_player_id  (pf_player_id)
#
FactoryBot.define do
  factory :player do
    sequence(:pf_player_id)
    regist_num { 1 }
    player_class { 1 }
    regist_day { '2020-10-12' }
    delete_day { '2020-10-12' }
    keirin_regist { '2020-10-12' }
    keirin_update { '2020-10-12' }
    keirin_delete { '2020-10-12' }
    keirin_expiration { '2020-10-12' }
    middle_regist { '2020-10-12' }
    middle_update { '2020-10-12' }
    middle_delete { '2020-10-12' }
    middle_expiration { '2020-10-12' }
    name_jp { 'MyString' }
    name_en { 'MyString' }
    birthday { '2020-10-12' }
    gender_code { 1 }
    country_code { 'MyString' }
    area_code { 'MyString' }
    graduate { 1 }
    current_rank_code { 'MyString' }
    next_rank_code { 'MyString' }
    height { '9.99' }
    weight { '9.99' }
    chest { '9.99' }
    thigh { '9.99' }
    leftgrip { '9.99' }
    rightgrip { '9.99' }
    vital { '9.99' }
    spine { '9.99' }
    lap_200 { 'MyString' }
    lap_400 { 'MyString' }
    lap_1000 { 'MyString' }
    max_speed { '9.99' }
    dash { '9.99' }
    duration { '9.99' }

    trait :with_original_info do
      association :player_original_info
    end
  end
end
