# frozen_string_literal: true

return if Rails.env.test?

creds = Aws::Credentials.new(
  Rails.application.credentials.aws_ses[:aws_access_key_id],
  Rails.application.credentials.aws_ses[:aws_secret_access_key]
)
Aws::Rails.add_action_mailer_delivery_method(:aws_sdk, credentials: creds, region: 'ap-northeast-1')
