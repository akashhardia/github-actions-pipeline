# frozen_string_literal: true

# == Schema Information
#
# Table name: coupon_seat_type_conditions
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  coupon_id           :bigint           not null
#  master_seat_type_id :bigint           not null
#
# Indexes
#
#  coupon_and_seat_type_index                                (coupon_id,master_seat_type_id) UNIQUE
#  index_coupon_seat_type_conditions_on_coupon_id            (coupon_id)
#  index_coupon_seat_type_conditions_on_master_seat_type_id  (master_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#
class CouponSeatTypeCondition < ApplicationRecord
  belongs_to :coupon
  belongs_to :master_seat_type

  # Validations -----------------------------------------------------------------------------------
  validates :coupon_id, presence: true
  validates :master_seat_type_id, presence: true
  validates :coupon_id, uniqueness: { scope: :master_seat_type_id }
end
