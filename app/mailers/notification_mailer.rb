# frozen_string_literal: true

# 通知メーラー
class NotificationMailer < ApplicationMailer
  def send_purchase_completion_notification_to_user(user, tickets, total_price)
    @user = user
    @event_date = event_date(tickets.first)
    @day_night = day_night(tickets.first)
    @seat_type = seat_type_names(tickets)
    @count = tickets.length
    @total_price = "￥#{total_price}（税込：￥#{total_price}）"
    @url = "#{Rails.application.credentials.environmental[:sales_front_host_name]}/mypage"
    mail subject: '【PIST6】チケット購入が完了しました', to: @user.profile.email
  end

  def send_transfer_notification_to_user(user, ticket)
    @user = user
    @event_date = event_date(ticket)
    @day_night = day_night(ticket)
    @seat_type = seat_type(ticket)
    mail subject: '【PIST6】チケット譲渡が完了しました', to: @user.profile.email
  end

  private

  def event_date(ticket)
    date = ticket.seat_sale.hold_daily_schedule.event_date
    week = %w[日 月 火 水 木 金 土][date.wday]
    date.strftime('%Y年%m月%d日') + "（#{week}）"
  end

  def day_night(ticket)
    hold_daily_schedule = ticket.seat_sale.hold_daily_schedule
    "#{hold_daily_schedule.am? ? 'デイ' : 'ナイト'}（開場：#{hold_daily_schedule.opening_display}）"
  end

  def seat_type_names(tickets)
    type_names = tickets.map { |ticket| seat_type(ticket) }
    type_name_size = type_names.group_by(&:itself).transform_values(&:size)
    display_names = ''
    type_name_size.each do |key, _value|
      display_names += "#{key}×#{type_name_size[key]}、"
    end
    display_names.chop
  end

  def seat_type(ticket)
    area_name = ticket.single? ? ticket.area_name : ''
    area_name + ticket.position.to_s
  end
end
