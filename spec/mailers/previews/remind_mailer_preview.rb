# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/remind_mailer

# リマインドメーラープレビュー
class RemindMailerPreview < ActionMailer::Preview
  def send_remind_to_user
    user = User.new(name: 'test_mail_previewer')
    RemindMailer.send_remind_to_user user
  end
end
