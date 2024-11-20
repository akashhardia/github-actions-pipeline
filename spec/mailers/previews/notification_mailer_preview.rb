# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer

# 通知メーラープレビュー
class NotificationMailerPreview < ActionMailer::Preview
  def send_purchase_completion_notification_to_user
    user = User.new(name: 'test_mail_previewer')
    NotificationMailer.send_purchase_completion_notification_to_user(user)
  end
end
