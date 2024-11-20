# frozen_string_literal: true

# == Schema Information
#
# Table name: user_coupons
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  coupon_id  :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_coupons_on_coupon_id              (coupon_id)
#  index_user_coupons_on_coupon_id_and_user_id  (coupon_id,user_id) UNIQUE
#  index_user_coupons_on_user_id                (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :user_coupon do
    coupon
    user
  end
end
