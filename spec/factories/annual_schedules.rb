# frozen_string_literal: true

# == Schema Information
#
# Table name: annual_schedules
#
#  id               :bigint           not null, primary key
#  active           :boolean          default(FALSE), not null
#  audience         :boolean
#  first_day        :date
#  girl             :boolean
#  grade_code       :string(255)
#  hold_days        :integer
#  period           :integer
#  pre_day          :boolean
#  promoter_section :integer
#  promoter_times   :integer
#  promoter_year    :integer
#  round            :integer
#  time_zone        :integer
#  track_code       :string(255)
#  year_name        :string(255)
#  year_name_en     :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pf_id            :string(255)      not null
#
# Indexes
#
#  index_annual_schedules_on_pf_id  (pf_id) UNIQUE
#
FactoryBot.define do
  factory :annual_schedule do
    sequence(:pf_id)
    first_day { '2021-08-02' }
    track_code { '32' }
    hold_days { 2 }
    pre_day { true }
    year_name { 'PIST6 2021-22 シーズン' }
    year_name_en { 'PIST6 2021-22 Season' }
    period { 3 }
    round { 1 }
    girl { false }
    promoter_times { 1 }
    promoter_section { 1 }
    time_zone { 0 }
    audience { false }
    grade_code { '0' }
    promoter_year { 2021 }
    active { false }
  end
end
