# frozen_string_literal: true

# == Schema Information
#
# Table name: template_coupons
#
#  id         :bigint           not null, primary key
#  note       :text(65535)
#  rate       :integer          not null
#  title      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :template_coupon do
    title { Faker::Lorem.sentence }
    rate { rand(1..9) * 10 }
    note { Faker::Lorem.sentence }
  end
end
