# frozen_string_literal: true

module Admin
  # 自動生成値コントローラ
  class TemplateSeatSaleSchedulesController < ApplicationController
    before_action :snakeize_params

    def index
      template_seat_sale_schedules = TemplateSeatSaleSchedule.order(:target_hold_schedule)
      serialized_template_seat_sale_schedules = ActiveModelSerializers::SerializableResource.new(template_seat_sale_schedules, each_serializer: TemplateSeatSaleScheduleSerializer, key_transform: :camel_lower)

      template_seat_sales = TemplateSeatSale.available.includes(:seat_sales, :template_seat_sale_schedules)
      serialized_template_seat_sales = ActiveModelSerializers::SerializableResource.new(template_seat_sales, each_serializer: TemplateSeatSaleSerializer, key_transform: :camel_lower)
      render json: { templateSeatSaleSchedules: serialized_template_seat_sale_schedules, templateSeatSales: serialized_template_seat_sales }
    end

    def update
      ApplicationRecord.transaction do
        params[:template_seat_sale_schedules].each do |pa|
          template_seat_sale_schedule = TemplateSeatSaleSchedule.find(pa['id'])
          template_seat_sale_schedule.update!(update_params_format(pa))
        end
      end

      head :ok
    end

    private

    def update_params_format(params)
      {
        admission_available_time: params['admission_available_time'],
        admission_close_time: params['admission_close_time'],
        sales_end_time: params['sales_end_time'],
        template_seat_sale_id: params['template_seat_sale_id']
      }
    end
  end
end
