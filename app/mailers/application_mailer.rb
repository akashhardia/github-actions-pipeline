# frozen_string_literal: true

# アプリケーションメーラー
class ApplicationMailer < ActionMailer::Base
  default from: Rails.env.test? ? 'from@example.com' : "PIST6 <#{Rails.application.credentials.aws_ses[:host]}>"
  layout 'mailer'
end
