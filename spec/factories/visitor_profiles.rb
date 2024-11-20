# frozen_string_literal: true

# == Schema Information
#
# Table name: visitor_profiles
#
#  id               :bigint           not null, primary key
#  address_detail   :string(255)
#  address_line     :string(255)
#  birthday         :date             not null
#  city             :string(255)
#  email            :string(255)      not null
#  family_name      :string(255)      not null
#  family_name_kana :string(255)      not null
#  given_name       :string(255)      not null
#  given_name_kana  :string(255)      not null
#  prefecture       :string(255)
#  zip_code         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  sixgram_id       :string(255)      not null
#  ticket_id        :bigint           not null
#
# Indexes
#
#  index_visitor_profiles_on_ticket_id  (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (ticket_id => tickets.id)
#
FactoryBot.define do
  factory :visitor_profile do
    ticket
    family_name { '山田' }
    given_name { '花子' }
    family_name_kana { 'ヤマダ' }
    given_name_kana { 'ハナコ' }
    birthday { Time.zone.now - 20.years }
    zip_code { 1_008_111 }
    prefecture { '東京都' }
    city { '千代田区千代田' }
    address_line { '1-1' }
    email { Faker::Internet.unique.email }
    sixgram_id { '999' }
  end
end
