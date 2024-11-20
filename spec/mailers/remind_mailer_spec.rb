# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemindMailer, type: :mailer do
  let(:user) { create(:user, :with_profile) }
  let(:remind_mail) { described_class.send_remind_to_user(user, [ticket]) }
  let(:ticket) { create(:ticket, user: user) }
  let(:hold_daily_schedule) { ticket.hold_daily_schedule }

  it 'メールの内容が正しいこと' do
    expect(remind_mail.from.first).to eq 'from@example.com'
    expect(remind_mail.to.first).to eq user.profile.email
    expect(remind_mail.subject).to eq '【PIST6】明日のご来場についてのご案内'
    expect(remind_mail.body.parts.first.body).to include "#{user.profile.family_name} 様"
    expect(remind_mail.body.parts.first.body).to include "デイ（開場：#{hold_daily_schedule.opening_display}　レース開始：#{hold_daily_schedule.start_display}）"
    expect(remind_mail.body.parts.first.body).to include ticket.seat_sale.hold_daily_schedule.event_date.strftime('%Y年%m月%d日')
  end
end
