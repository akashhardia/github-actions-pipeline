# frozen_string_literal: true

Rails.application.configure do
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.enabled = true unless Rails.env.test?
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.logger = ActiveSupport::Logger.new($stdout)
  config.lograge.keep_original_rails_log = true if Rails.env.development?
  config.lograge.ignore_actions = ['HealthzController#liveness']

  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host,
      request_id: controller.request.request_id
    }
  end

  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    data = {
      request_id: event.payload[:request_id],
      level: 'info',
      login_id: event.payload[:login_id],
      ip: event.payload[:ip],
      referer: event.payload[:referer],
      user_agent: event.payload[:user_agent],
      time: Time.zone.now.iso8601,
      params: event.payload[:params].except(*exceptions)
    }
    if event.payload[:exception]
      data[:level] = 'error'
      data[:exception] = event.payload[:exception]
      data[:exception_backtrace] = event.payload[:exception_object]&.backtrace
    end
    data
  end
end
