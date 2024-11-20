# frozen_string_literal: true

module Admin
  # 外部APIログコントローラ
  class ExternalApiLogsController < ApplicationController
    before_action :set_external_api_log, only: [:show]

    def index
      external_api_logs = ExternalApiLog.filter_by_path(params[:path]).order(id: 'DESC').page(params[:page] || 1).per(10)
      pagination = resources_with_pagination(external_api_logs)
      serialized_external_api_logs = ActiveModelSerializers::SerializableResource.new(external_api_logs, each_serializer: ExternalApiLogSerializer, action: :index, key_transform: :camel_lower)

      render json: { externalApiLogs: serialized_external_api_logs, pagination: pagination }
    end

    def show
      render json: @external_api_log, serializer: ExternalApiLogSerializer, key_transform: :camel_lower
    end

    private

    def set_external_api_log
      @external_api_log = ExternalApiLog.find(params[:id])
    end
  end
end
