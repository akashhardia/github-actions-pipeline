# frozen_string_literal: true

# 認証メーラー
class AuthorizeMailer < ApplicationMailer
  def send_authorize_code_to_user(user, uuid)
    @user = user
    @uuid = uuid
    @url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/signup/email_auth/#{uuid}"
    mail subject: '【PIST6】仮登録が完了しました', to: @user.profile.email
  end

  def send_authorize_completed_to_user(user)
    @user = user
    @url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/mypage"
    @ticket_url = 'https://www.pist6.com/ticket'
    lock_key = "profile_#{user.id}"
    new_email = Redis.current.get(lock_key)
    mail subject: '【PIST6】本登録が完了しました', to: new_email
  end

  def resend_authorize_code_to_user(user, uuid)
    @user = user
    @uuid = uuid
    lock_key = "profile_#{user.id}"
    new_email = Redis.current.get(lock_key)
    @url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/signup/email_auth/#{uuid}"
    mail subject: '【PIST6】メール認証をお済ませください', to: new_email
  end

  def send_update_completed_to_user(user, uuid)
    @user = user
    @uuid = uuid
    lock_key = "profile_#{user.id}"
    new_email = Redis.current.get(lock_key)
    @url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/signup/email_auth/#{uuid}"
    mail subject: '【PIST6】会員情報の変更が完了しました', to: new_email
  end

  def send_unsubscribe_mail_to_user(user, uuid)
    @user = user
    @uuid = uuid
    @url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/users/#{uuid}/unsubscribe"
    mail subject: '【PIST6】退会手続きのご案内', to: @user.profile.email
  end

  def send_unsubscribe_complete_mail_to_user(user)
    @user = user
    mail subject: '【PIST6】退会手続きが完了しました', to: @user.profile.email
  end
end
