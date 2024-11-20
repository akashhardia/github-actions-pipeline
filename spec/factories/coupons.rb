# frozen_string_literal: true

# == Schema Information
#
# Table name: coupons
#
#  id                       :bigint           not null, primary key
#  approved_at              :datetime
#  available_end_at         :datetime         not null
#  canceled_at              :datetime
#  scheduled_distributed_at :datetime
#  user_restricted          :boolean          default(FALSE), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  template_coupon_id       :bigint           not null
#
# Indexes
#
#  index_coupons_on_template_coupon_id  (template_coupon_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_coupon_id => template_coupons.id)
#
FactoryBot.define do
  factory :coupon do
    template_coupon
    available_end_at { Time.zone.now + rand(5..9).hour }
    scheduled_distributed_at { available_end_at - rand(0..4).hour if available_end_at.present? }
    approved_at { available_end_at - rand(0..4).hour }
    canceled_at { available_end_at - rand(0..4).hour }

    trait :available_end_at_nil do
      available_end_at { nil }
      scheduled_distributed_at { Time.zone.now }
      approved_at { Time.zone.now }
      canceled_at { Time.zone.now }
    end

    trait :available_coupon do
      canceled_at { nil }
      scheduled_distributed_at { Time.zone.now - rand(1..4).hour }
      approved_at { Time.zone.now - rand(1..4).hour }
    end

    trait :cancel_possible_coupon do
      canceled_at { nil }
      scheduled_distributed_at { Time.zone.now + rand(1..3).hour }
      approved_at { Time.zone.now + rand(1..3).hour }
    end
  end
end
