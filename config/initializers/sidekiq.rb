# frozen_string_literal: true

require 'sidekiq'

Sidekiq.configure_server do |config|
  config.redis = {
    url: "redis://#{ENV['REDIS_HOST']}:6379/0",
    namespace: "chiba_250_sidekiq_#{Rails.env}",
    id: nil
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "redis://#{ENV['REDIS_HOST']}:6379/0",
    namespace: "chiba_250_sidekiq_#{Rails.env}",
    id: nil
  }
end
