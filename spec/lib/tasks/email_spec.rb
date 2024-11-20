# frozen_string_literal: true

require 'rails_helper'
require 'rake_helper'

describe 'email raketask' do # rubocop:disable RSpec/DescribeClass
  # 一日前のイベントのチケットを所持しているユーザー
  let(:user_with_after_event) { create(:user, :with_ticket_after_event, :with_profile) }

  # 本日のイベントのチケットを所持しているユーザー
  let(:user_with_today_event) { create(:user, :with_ticket_today_event, :with_profile) }

  # 明日のイベントのチケットを所持しているユーザー
  let(:user_with_before_event_one_day) { create(:user, :with_ticket_before_event_one_day, :with_profile) }

  # 明後日のイベントのチケットを所持しているユーザー
  let(:user_with_before_event_over_one_day) { create(:user, :with_ticket_before_event_over_one_day, :with_profile) }
  let(:remind_mail) { Rake.application['email:remind'] }

  describe 'email:remind' do
    context '翌日が１販売情報しかない場合' do
      before do
        user_with_after_event
        user_with_today_event
        user_with_before_event_over_one_day

        create(:ticket, :after_event, user: target_user, status: :sold)
        create(:ticket, :today_event, user: target_user, status: :sold)
        create(:ticket, :before_event_over_one_day, user: target_user, status: :sold)
      end

      let(:target_user) { user_with_before_event_one_day }

      it '翌日が開催日のチケットを持つユーザーに対象のチケット分のみ送信されていること' do
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { remind_mail.execute } }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'ユーザーが退会済みの場合、メールが送信されないこと' do
        target_user.touch(:deleted_at)
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { remind_mail.execute } }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context '翌日が複数の販売情報がある場合' do
      before do
        user_with_after_event
        user_with_today_event
        user_with_before_event_over_one_day

        create(:ticket, :after_event, user: target_user, status: :sold)
        create(:ticket, :today_event, user: target_user, status: :sold)
        create(:ticket, :before_event_over_one_day, user: target_user, status: :sold)
        target_ticket = create(:ticket, :before_event_one_day, user: target_user, status: :sold)
        # target_ticketと同じseat_saleのチケットを作成
        create(:ticket, seat_type: target_ticket.seat_type, seat_area: target_ticket.seat_area, user: target_user, status: :sold)
      end

      let(:target_user) { user_with_before_event_one_day }

      it '翌日が開催日のチケットを持つユーザーに対象のチケット分が販売情報単位で送信されていること' do
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { remind_mail.execute } }.to change { ActionMailer::Base.deliveries.count }.by(2)
      end

      it 'ユーザーが退会済みの場合、メールが送信されないこと' do
        target_user.touch(:deleted_at)
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { remind_mail.execute } }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context '翌日の開催の販売が停止された場合' do
      before do
        user_with_after_event
        user_with_today_event
        user_with_before_event_over_one_day

        user_with_before_event_one_day.tickets.each do |ticket|
          ticket.seat_sale.update(sales_status: 'discontinued')
        end

        target_user = user_with_before_event_one_day
        create(:ticket, :after_event, user: target_user, status: :sold)
        create(:ticket, :today_event, user: target_user, status: :sold)
        create(:ticket, :before_event_over_one_day, user: target_user, status: :sold)
      end

      it 'メール送信されないこと' do
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { remind_mail.execute } }.to change { ActionMailer::Base.deliveries.count }.by(0)
      end
    end
  end
end
