# frozen_string_literal: true

# リマインドメーラー
class RemindMailer < ApplicationMailer
  def send_remind_to_user(user, tickets)
    @user = user
    @event_date = event_date(tickets.first)
    @hold_daily_schedule = tickets.first.hold_daily_schedule
    @mypage_url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/mypage"
    @admission_url = "#{Rails.application.credentials.environmental[:mt_host_name]}/guide/ticket-guide/howto-admission/"
    @transfer_url = "#{Rails.application.credentials.environmental[:mt_host_name]}/guide/ticket-guide/howto-transfer/"

    mail subject: '【PIST6】明日のご来場についてのご案内', to: @user.profile.email
  end

  def event_date(ticket)
    date = ticket.seat_sale.hold_daily_schedule.event_date
    week = %w[日 月 火 水 木 金 土][date.wday]
    date.strftime('%Y年%m月%d日') + "（#{week}）"
  end
end
