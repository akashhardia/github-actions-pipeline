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
class SeatSaleSerializer < ActiveModel::Serializer
  attributes :id,
             :sales_end_at,
             :sales_start_at,
             :sales_status,
             :hold_name_jp,
             :admission_progress,
             :sales_progress,
             :daily_no,
             :admission_available_at,
             :admission_close_at,
             :event_date,
             :refund_at

  attribute :template_seat_sale_title, if: :index?
  attribute :ticket_count, if: :index?

  def initialize(serializer, options = {})
    @instance_options = options
    super
  end

  def index?
    @instance_options[:action] == :index
  end

  def template_seat_sale_title
    object.template_seat_sale.title
  end

  def event_date
    object.hold_daily.event_date
  end

  def hold_name_jp
    object.hold_daily_schedule.hold_daily.hold_name_jp
  end

  def ticket_count
    Ticket.sold.includes(seat_type: :seat_sale).where(seat_sale: { id: object.id }).count
  end

  def daily_no
    HoldDailySchedule::DAILY_NO[object.hold_daily_schedule.daily_no.to_sym]
  end
end
