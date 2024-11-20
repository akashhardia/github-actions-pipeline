# frozen_string_literal: true

# == Schema Information
#
# Table name: coupon_hold_daily_conditions
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  coupon_id              :bigint           not null
#  hold_daily_schedule_id :bigint           not null
#
# Indexes
#
#  coupon_and_hold_daily_index                                   (coupon_id,hold_daily_schedule_id) UNIQUE
#  index_coupon_hold_daily_conditions_on_coupon_id               (coupon_id)
#  index_coupon_hold_daily_conditions_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#
FactoryBot.define do
  factory :coupon_hold_daily_condition do
    coupon
    hold_daily_schedule
  end
end
