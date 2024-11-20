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
class Coupon < ApplicationRecord
  belongs_to :template_coupon
  has_many :user_coupons, dependent: :destroy
  has_many :coupon_hold_daily_conditions, dependent: :destroy
  has_many :coupon_seat_type_conditions, dependent: :destroy
  has_many :hold_daily_schedules, through: :coupon_hold_daily_conditions
  has_many :hold_dailies, through: :hold_daily_schedules
  has_many :master_seat_types, through: :coupon_seat_type_conditions
  has_many :users, through: :user_coupons
  has_many :orders, through: :user_coupons

  # Validations -----------------------------------------------------------------------------------
  validates :available_end_at, presence: true
  validates_with CouponStartAtMustOverEndAtValidator

  delegate :title, :rate, :note, to: :template_coupon

  scope :available, ->(time) {
                      where(canceled_at: nil)
                        .where.not(approved_at: nil)
                        .where('available_end_at > ? and scheduled_distributed_at < ?', time, time)
                    }

  scope :available_to_user, ->(user, time, cart_coupon = nil) {
    ids = available(time).available(Time.zone.now).includes(:coupon_hold_daily_conditions).each_with_object([]) do |coupon, result|
      result << coupon.id if coupon.be_available_hold_daily && coupon.be_unused_user_coupon(user, cart_coupon)
    end
    where(id: ids)
  }

  # 新規登録時に配布するクーポン：配布予定日は過ぎていないくても対象になる
  scope :distribution, ->(time) {
                         where(canceled_at: nil)
                           .where.not(approved_at: nil)
                           .where('available_end_at > ?', time)
                           .where(user_restricted: false)
                       }

  # クーポンがuserが未使用かどうかを返す
  def be_unused_user_coupon(user, cart_coupon)
    user_coupon = user_coupons.find_by(user_id: user.id)
    return false if user_coupon.blank?

    return true if cart_coupon.present? && user_coupon.order.present? && user_coupon.coupon_id == cart_coupon.id

    return true if Payment.where(order_id: Order.where(user_coupon_id: user_coupon.id)).find_by(payment_progress: 'captured').blank?

    user_coupon.order.blank?
  end

  # クーポンが現在購入可能な開催に紐づいているかどうかを返す
  def be_available_hold_daily
    return true if coupon_hold_daily_conditions.blank?

    coupon_hold_daily_conditions.includes(hold_daily_schedule: :seat_sales).any? { |condition| condition.hold_daily_schedule.available? }
  end
end
