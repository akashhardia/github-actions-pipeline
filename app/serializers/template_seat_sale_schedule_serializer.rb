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
class TemplateSeatSaleScheduleSerializer < ActiveModel::Serializer
  attributes :id, :admission_available_time, :admission_close_time, :sales_end_time, :template_seat_sale_id, :target_daily, :target_time

  # 開催の１日目、２日目を返す
  def target_daily
    object.target_hold_schedule_before_type_cast < 2 ? '１' : '２'
  end

  # 開催時間、デイ、ナイトを返す
  def target_time
    object.target_hold_schedule_before_type_cast.even? ? 'デイ' : 'ナイト'
  end
end
