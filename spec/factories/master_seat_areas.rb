# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_areas
#
#  id           :bigint           not null, primary key
#  area_code    :string(255)      not null
#  area_name    :string(255)      not null
#  position     :string(255)
#  sub_code     :string(255)
#  sub_position :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :master_seat_area do
    area_code { Faker::Alphanumeric.unique.alpha }
    area_name { Faker::Alphanumeric.unique.alpha }
    position { 'default' }
  end
end
