# frozen_string_literal: true

module Admin
  # 年間スケジュールコントローラ
  class AnnualSchedulesController < ApplicationController
    def index
      annual_schedules = if params[:date].present?
                           AnnualSchedule.where('first_day >= ?', params[:date])
                         else
                           AnnualSchedule.all
                         end

      render json: annual_schedules, each_serializer: Admin::AnnualScheduleSerializer, key_transform: :camel_lower
    end

    def change_activation
      annual_schedule = AnnualSchedule.find(params[:id])
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.annual_schedules.active_blank') if params[:active].nil?

      annual_schedule.update!(active: params[:active])

      head :ok
    end
  end
end
