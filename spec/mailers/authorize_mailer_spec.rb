# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizeMailer, type: :mailer do
  let(:user) { create(:user, :with_profile) }
  let(:uuid) { 'testuuid' }
  let(:authorize_mail) { described_class.send_authorize_code_to_user(user, uuid) }
  let(:authorize_comleted_mail) { described_class.send_authorize_completed_to_user(user) }
  let(:resend_authorize_mail) { described_class.resend_authorize_code_to_user(user, uuid) }
  let(:send_update_completed_mail) { described_class.send_update_completed_to_user(user, uuid) }
  let(:send_unsubscribe_mail) { described_class.send_unsubscribe_mail_to_user(user, uuid) }
  let(:send_unsubscribe_complete_mail) { described_class.send_unsubscribe_complete_mail_to_user(user) }

  it 'メールの内容が正しいこと' do
    expect(authorize_mail.from.first).to eq 'from@example.com'
    expect(authorize_mail.to.first).to eq user.profile.email
    expect(authorize_mail.subject).to eq '【PIST6】仮登録が完了しました'
  end

  it '認証完了メールの内容が正しいこと' do
    expect(authorize_comleted_mail.from.first).to eq 'from@example.com'
    expect(authorize_comleted_mail.to.first).to eq user.profile.email
    expect(authorize_comleted_mail.subject).to eq '【PIST6】本登録が完了しました'
  end

  it '再認証メールの内容が正しいこと' do
    expect(resend_authorize_mail.from.first).to eq 'from@example.com'
    expect(resend_authorize_mail.to.first).to eq user.profile.email
    expect(resend_authorize_mail.subject).to eq '【PIST6】メール認証をお済ませください'
  end

  it '会員情報変更の完了メールの内容が正しいこと' do
    expect(send_update_completed_mail.from.first).to eq 'from@example.com'
    expect(send_update_completed_mail.to.first).to eq user.profile.email
    expect(send_update_completed_mail.subject).to eq '【PIST6】会員情報の変更が完了しました'
  end

  it '会員退会手続きのメールの内容が正しいこと' do
    expect(send_unsubscribe_mail.from.first).to eq 'from@example.com'
    expect(send_unsubscribe_mail.to.first).to eq user.profile.email
    expect(send_unsubscribe_mail.subject).to eq '【PIST6】退会手続きのご案内'
  end

  it '会員退会完了のメールの内容が正しいこと' do
    expect(send_unsubscribe_complete_mail.from.first).to eq 'from@example.com'
    expect(send_unsubscribe_complete_mail.to.first).to eq user.profile.email
    expect(send_unsubscribe_complete_mail.subject).to eq '【PIST6】退会手続きが完了しました'
  end
end
