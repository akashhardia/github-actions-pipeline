# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/authorize_mailer

# 通知メーラープレビュー
class AuthorizeMailerPreview < ActionMailer::Preview
  def send_authorize_code_to_user
    user = User.new(name: 'test_mail_previewer')
    uuid = 'testuuid'
    AuthorizeMailer.send_authorize_code_to_user(user, uuid)
  end

  def send_authorize_completed_to_user
    user = User.new(name: 'test_mail_previewer')
    AuthorizeMailer.send_authorize_completed_to_user(user)
  end

  def resend_authorize_code_to_user
    user = User.new(name: 'test_mail_previewer')
    uuid = 'testuuid'
    AuthorizeMailer.resend_authorize_code_to_user(user, uuid)
  end

  def send_update_completed_to_user
    user = User.new(name: 'test_mail_previewer')
    uuid = 'testuuid'
    AuthorizeMailer.send_update_completed_to_user(user, uuid)
  end

  def send_unsubscribe_mail_to_user
    user = User.new(name: 'test_mail_previewer')
    uuid = 'testuuid'
    AuthorizeMailer.send_unsubscribe_mail_to_user(user, uuid)
  end
end
