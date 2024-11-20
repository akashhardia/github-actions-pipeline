# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationMailer, type: :mailer do
  let(:user) { create(:user, :with_profile) }

  describe 'send_purchase_completion_notification_to_user' do
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:template_seat_type1) { create(:template_seat_type, price: 1000) }
    let(:template_seat_type2) { create(:template_seat_type, price: 2000) }
    let(:seat_type1) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type1) }
    let(:seat_type2) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type2) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
    let(:ticket2) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
    let(:ticket3) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
    let(:ticket4) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
    let(:total_price) { 6000 }
    let(:notification_mail) { described_class.send_purchase_completion_notification_to_user(user, [ticket1, ticket2, ticket3, ticket4], total_price) }

    it 'メールの内容が正しいこと' do
      expect(notification_mail.from.first).to eq 'from@example.com'
      expect(notification_mail.to.first).to eq user.profile.email
      expect(notification_mail.subject).to eq '【PIST6】チケット購入が完了しました'
      expect(notification_mail.body.parts.first.body).to include "デイ（開場：#{ticket1.hold_daily_schedule.opening_display}）"
      expect(notification_mail.body.parts.first.body).to include ticket1.seat_sale.hold_daily_schedule.event_date.strftime('%Y年%m月%d日')
      expect(notification_mail.body.parts.first.body).to include ticket1.area_name + ticket1.position
      expect(notification_mail.body.parts.first.body).to include '価格：￥6000（税込：￥6000）'
    end
  end

  describe 'send_transfer_notification_to_user' do
    let(:ticket) { create(:ticket, user: user) }
    let(:notification_transfer_mail) { described_class.send_transfer_notification_to_user(user, ticket) }

    it 'メールの内容が正しいこと' do
      expect(notification_transfer_mail.from.first).to eq 'from@example.com'
      expect(notification_transfer_mail.to.first).to eq user.profile.email
      expect(notification_transfer_mail.subject).to eq '【PIST6】チケット譲渡が完了しました'
      expect(notification_transfer_mail.body.parts.first.body).to include "デイ（開場：#{ticket.hold_daily_schedule.opening_display}）"
      expect(notification_transfer_mail.body.parts.first.body).to include ticket.seat_sale.hold_daily_schedule.event_date.strftime('%Y年%m月%d日')
      expect(notification_transfer_mail.body.parts.first.body).to include ticket.area_name + ticket.position
    end
  end
end
