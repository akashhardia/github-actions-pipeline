# frozen_string_literal: true

# == Schema Information
#
# Table name: word_codes
#
#  id         :bigint           not null, primary key
#  code       :string(255)
#  identifier :string(255)      not null
#  name1      :string(255)
#  name2      :string(255)
#  name3      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  master_id  :string(255)      not null
#
# Indexes
#
#  index_word_codes_on_master_id  (master_id) UNIQUE
#
FactoryBot.define do
  factory :word_code do
    master_id { Faker::Number.number(digits: 4).to_s }
    identifier { Faker::Number.number(digits: 3).to_s }
    code { Faker::Code.nric }
    name1 { nil }
    name2 { nil }
    name3 { nil }
  end
end
