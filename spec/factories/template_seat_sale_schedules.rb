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
FactoryBot.define do
  factory :template_seat_sale_schedule do
    template_seat_sale
    sales_end_time { '14:00' }
    admission_available_time { '10:30' }
    admission_close_time { '14:30' }
    target_hold_schedule { 0 }
  end
end
