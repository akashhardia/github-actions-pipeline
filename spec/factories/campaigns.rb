# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  approved_at   :datetime
#  code          :string(255)      not null
#  description   :string(255)
#  discount_rate :integer          not null
#  displayable   :boolean          default(TRUE)
#  end_at        :datetime
#  start_at      :datetime
#  terminated_at :datetime
#  title         :string(255)      not null
#  usage_limit   :integer          default(9999999), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_campaigns_on_code  (code) UNIQUE
#
FactoryBot.define do
  factory :campaign do
    title { 'テストキャンペーン' }
    code { SecureRandom.alphanumeric(10) }
    discount_rate { 10 }
    usage_limit { 3 }
    description { 'テストキャンペーンです。' }
    start_at { nil }
    end_at { nil }
    approved_at { nil }
    terminated_at { nil }
    displayable { true }
  end
end
