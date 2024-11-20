# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_sales
#
#  id                     :bigint           not null, primary key
#  admission_available_at :datetime         not null
#  admission_close_at     :datetime         not null
#  force_sales_stop_at    :datetime
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
class SeatSaleIndexSerializer < ApplicationSerializer
  attributes :id,
             :sales_end_at,
             :sales_start_at,
             :sales_status,
             :admission_progress,
             :sales_progress,
             :admission_available_at,
             :admission_close_at
end
