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
FactoryBot.define do
  factory :seat_sale do
    template_seat_sale
    hold_daily_schedule
    sales_status { :before_sale }
    sales_start_at { Time.zone.now + 5.hours }
    sales_end_at { Time.zone.now + 6.hours }
    admission_available_at { Time.zone.now + 6.hours }
    admission_close_at { Time.zone.now + 10.hours }

    trait :available do
      sales_status { :on_sale }
      sales_start_at { Time.zone.now - 1.hour }
      sales_end_at { Time.zone.now + 12.hours }
    end

    trait :in_term do
      sales_start_at { Time.zone.now - 1.hour }
      sales_end_at { Time.zone.now + 12.hours }
    end

    trait :out_of_term do
      sales_start_at { Time.zone.now - 1.day }
      sales_end_at { Time.zone.now - 12.hours }
    end

    trait :in_admission_term do
      sales_status { :on_sale }
      admission_available_at { Time.zone.now - 1.hour }
      admission_close_at { Time.zone.now + 12.hours }
    end

    trait :after_closing do
      admission_available_at { Time.zone.now - 1.day }
      admission_close_at { Time.zone.now - 12.hours }
    end

    trait :not_selling do
      sales_start_at { Time.zone.now + 1.day }
      sales_end_at { Time.zone.now + 36.hours }
    end

    trait :selling do
      sales_start_at { Time.zone.now - 1.day }
      sales_end_at { Time.zone.now }
    end

    trait :before_admission_close_time do
      admission_available_at { Time.zone.now - 2.days }
      admission_close_at { Time.zone.now + 35.hours }
    end

    trait :after_admission_close_time do
      admission_available_at { Time.zone.now - 2.days }
      admission_close_at { Time.zone.now - 1.day }
    end

    trait :after_event do
      hold_daily_schedule { create(:hold_daily_schedule, hold_daily: create(:hold_daily, :after_event)) }
    end

    trait :today_event do
      hold_daily_schedule { create(:hold_daily_schedule, hold_daily: create(:hold_daily, :today_event)) }
    end

    trait :before_event_one_day do
      hold_daily_schedule { create(:hold_daily_schedule, hold_daily: create(:hold_daily, :before_event_one_day)) }
    end

    trait :before_event_over_one_day do
      hold_daily_schedule { create(:hold_daily_schedule, hold_daily: create(:hold_daily, :before_event_over_one_day)) }
    end
  end
end
