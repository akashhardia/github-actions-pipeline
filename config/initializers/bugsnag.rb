# frozen_string_literal: true

Bugsnag.configure do |config|
  config.api_key = 'd2416525ac9a4991765360fd97bea232'
  config.notify_release_stages = %w[production staging]
end
