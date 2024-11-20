# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :master_seat_type do
    name { 'MyString' }
  end
end
