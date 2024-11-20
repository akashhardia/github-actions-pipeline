# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id               :bigint           not null, primary key
#  address_detail   :string(255)
#  address_line     :string(255)
#  auth_code        :text(65535)
#  birthday         :date             not null
#  city             :string(255)
#  email            :string(255)      not null
#  family_name      :string(255)      not null
#  family_name_kana :string(255)      not null
#  given_name       :string(255)      not null
#  given_name_kana  :string(255)      not null
#  mailmagazine     :boolean          default(FALSE), not null
#  ng_user_check    :boolean          default(TRUE), not null
#  phone_number     :string(255)
#  prefecture       :string(255)
#  zip_code         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :profile do
    user
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
    mailmagazine { true }
    phone_number { '09090909090' }
  end
end
