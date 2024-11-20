# frozen_string_literal: true

# == Schema Information
#
# Table name: player_original_infos
#
#  id               :bigint           not null, primary key
#  comment          :string(255)
#  evaluation       :integer
#  experience       :integer
#  first_name_en    :string(255)
#  first_name_jp    :string(255)
#  free1            :text(65535)
#  free2            :text(65535)
#  free3            :text(65535)
#  free4            :text(65535)
#  free5            :text(65535)
#  free6            :text(65535)
#  free7            :text(65535)
#  free8            :text(65535)
#  growth           :integer
#  last_name_en     :string(255)
#  last_name_jp     :string(255)
#  major_title      :string(255)
#  mental           :integer
#  nickname         :string(255)
#  original_record  :integer
#  pist6_title      :string(255)
#  popular          :integer
#  power            :integer
#  race_type        :string(255)
#  round_best       :string(255)
#  season_best      :string(255)
#  speed            :integer
#  stamina          :integer
#  technique        :integer
#  year_best        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pf_250_regist_id :string(255)
#  player_id        :bigint           not null
#
# Indexes
#
#  index_player_original_infos_on_pf_250_regist_id  (pf_250_regist_id)
#  index_player_original_infos_on_player_id         (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
FactoryBot.define do
  factory :player_original_info do
    pf_250_regist_id { Faker::Number.unique.number(digits: 4) }
    free2 { %w[012 003].sample }
    free3 { '1989/3/21' }
    free4 { '180' }
    free5 { '72.5' }
    last_name_en { %w[Tanaka Tashiro Aiba Eto].sample }
    association :player
    first_name_en { %w[Tanaka Tashiro Aiba Eto].sample }
    speed { 10 }
    stamina { 10 }
    power { 10 }
    technique { 10 }
    mental { 10 }
    evaluation { 10 }
    nickname { 'aaa' }
    first_name_jp { %w[田中 田代 相葉 江藤].sample }
    last_name_jp { %w[田中 田代 相葉 江藤].sample }
    round_best { 'mm:ss.MMMM' }
    year_best { 'mm:ss.MMMM' }
    major_title { 'test' }
    pist6_title { 'bb' }
  end
end