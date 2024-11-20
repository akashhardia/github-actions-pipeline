# frozen_string_literal: true

# == Schema Information
#
# Table name: word_names
#
#  id           :bigint           not null, primary key
#  abbreviation :string(255)
#  lang         :string(255)      not null
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  word_code_id :integer          not null
#
FactoryBot.define do
  factory :word_name do
    word_code
    lang { 0 }
    name { 'サンプル' }
  end
end
