# frozen_string_literal: true

namespace :email do
  desc '翌日開催のチケットを所持しているユーザーを探し、対象のユーザー全員にメールを送信する'
  task remind: :environment do
    # 明日開催でuser_idが入っているチケット
    target_tickets = Ticket.sold.includes(:user, seat_type: { seat_sale: [hold_daily_schedule: :hold_daily] })
                           .where.not(user_id: nil)
                           .where.not(seat_sales: { sales_status: 'discontinued' })
                           .where({ hold_dailies: { event_date: Time.zone.tomorrow } })
    # 対象のチケットをseat_saleとuser_idでグルーピング
    target_tickets.group_by { |ticket| "#{ticket.seat_sale.id}-#{ticket.user_id}" }.each do |_key, value|
      RemindMailer.send_remind_to_user(value.first.user, value).deliver_later unless value.first.user.unsubscribed?
    end
  end
end
