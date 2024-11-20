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
class CouponSerializer < ActiveModel::Serializer
  attributes :id, :available_end_at, :canceled_at, :approved_at, :scheduled_distributed_at,
             :template_coupon_id, :title, :rate, :note, :user_restricted, :hold_dailies, :seat_types

  # クーポン一覧ページでのみ使用する値
  attribute :created_at, if: :index?
  attribute :updated_at, if: :index?

  def initialize(serializer, options = {})
    @instance_options = options
    super
  end

  def index?
    @instance_options[:action] == :index
  end

  def hold_dailies
    # 一覧の場合は存在しているのが分かれば良いのでidsのみ返す
    return object.hold_daily_schedules.ids if index?

    ActiveModelSerializers::SerializableResource.new(object.hold_daily_schedules.includes(hold_daily: :hold), each_serializer: HoldDailyScheduleForCouponSerializer, key_transform: :camel_lower)
  end

  def seat_types
    # 一覧の場合は存在しているのが分かれば良いのでidsのみ返す
    return object.master_seat_types.ids if index?

    object.master_seat_types.map do |seat_type|
      {
        id: seat_type.id,
        name: seat_type.name
      }
    end
  end

  delegate :created_at, to: :object

  delegate :updated_at, to: :object
end
