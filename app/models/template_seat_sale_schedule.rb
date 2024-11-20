# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_sale_schedules
#
#  id                       :bigint           not null, primary key
#  admission_available_time :string(255)      not null
#  admission_close_time     :string(255)      not null
#  sales_end_time           :string(255)      not null
#  target_hold_schedule     :integer          not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  template_seat_sale_id    :bigint           not null
#
# Indexes
#
#  index_template_seat_sale_schedules_on_template_seat_sale_id  (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
class TemplateSeatSaleSchedule < ApplicationRecord
  belongs_to :template_seat_sale

  # Validations -----------------------------------------------------------------------------------
  validates :admission_available_time, presence: true
  validates :admission_close_time, presence: true
  validates :sales_end_time, presence: true
  validates :target_hold_schedule, presence: true
  validates_with TemplateSeatSaleScheduleValidator

  # 対象の開催をこちらで把握する
  enum target_hold_schedule: {
    first_day: 0, # 1日目のデイ
    first_night: 1, # 1日目のナイト
    second_day: 2, # 2日目のデイ
    second_night: 3 # 2日目のナイト
  }

  class << self
    # hold_daily_scheduleを渡して、対象のsales_auto_generate_valueを返す、対象がなければnilを返す
    def target_find_by(hold_daily_schedule)
      day = hold_daily_schedule.hold_daily.hold_daily
      time = hold_daily_schedule.daily_no

      find_by(target_hold_schedule: target_hold_schedule_value(day, time))
    end

    private

    def target_hold_schedule_value(day, time)
      day_time = [day, time]
      case day_time
      when [1, 'am']
        0
      when [1, 'pm']
        1
      when [2, 'am']
        2
      when [2, 'pm']
        3
      end
    end
  end
end
