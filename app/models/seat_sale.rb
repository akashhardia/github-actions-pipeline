# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_sales
#
#  id                     :bigint           not null, primary key
#  admission_available_at :datetime         not null
#  admission_close_at     :datetime         not null
#  force_sales_stop_at    :datetime
#  refund_at              :datetime
#  refund_end_at          :datetime
#  sales_end_at           :datetime         not null
#  sales_start_at         :datetime         not null
#  sales_status           :integer          default("before_sale"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  hold_daily_schedule_id :bigint
#  template_seat_sale_id  :bigint
#
# Indexes
#
#  index_seat_sales_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#  index_seat_sales_on_template_seat_sale_id   (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
class SeatSale < ApplicationRecord
  belongs_to :template_seat_sale
  belongs_to :hold_daily_schedule
  has_many :orders, dependent: :nullify
  has_many :seat_types, dependent: :destroy
  has_many :seat_areas, dependent: :destroy
  has_many :tickets, through: :seat_types
  has_many :seat_type_options, through: :seat_types

  delegate :hold_daily, to: :hold_daily_schedule
  delegate :hold, to: :hold_daily

  enum sales_status: {
    before_sale: 0,
    on_sale: 1,
    discontinued: 3
  }

  # Scope -----------------------------------------------------------------------------------
  scope :sorted_with_event_date_daily_no, -> { includes(hold_daily_schedule: :hold_daily).order('hold_dailies.event_date').order('hold_daily_schedules.daily_no') }

  # Validations -----------------------------------------------------------------------------------
  validates :admission_available_at, presence: true
  validates :admission_close_at, presence: true
  validates :sales_end_at, presence: true
  validates :sales_start_at, presence: true
  validates :sales_status, presence: true
  validates :template_seat_sale_id, presence: true
  validates_with StartAtMustOverEndAtValidator

  # チケット販売可能かどうかのチェック
  # true->販売可能 false->不可能
  def available?
    on_sale? && check_sales_schedule?
  end

  # クーポン作成可能かどうかのチェック
  # true->作成可能 false->不可能
  def can_create_coupon?
    !discontinued? && Time.zone.now <= sales_end_at
  end

  # 販売期間確認
  # true->販売期間内 false->販売期間外
  def check_sales_schedule?
    Time.zone.now.between?(sales_start_at, sales_end_at)
  end

  def admission_available?
    Time.zone.now >= admission_available_at
  end

  def admission_close?
    admission_close_at < Time.zone.now
  end

  def already_on_sale?
    on_sale? && sales_start_at < Time.zone.now
  end

  def selling_discontinued!
    # 販売開始後に強制中止した時間を記録
    self.force_sales_stop_at = Time.zone.now if already_on_sale?
    self.sales_status = :discontinued
    save!
  end

  def accounting_target?
    # 販売開始後
    return true if already_on_sale?
    # 販売開始後中止
    return true if force_sales_stop_at.present?

    # 販売開始前, 販売開始前中止など
    false
  end

  def sales_progress
    return :discontinued if discontinued?
    return :unapproved_sale if before_sale?
    return :before_sale if Time.zone.now < sales_start_at
    return :end_of_sale if Time.zone.now > sales_end_at

    :on_sale
  end

  def admission_progress
    if admission_close?
      :finished
    elsif admission_available?
      :in_progress
    else
      :not_started
    end
  end
end
