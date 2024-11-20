# frozen_string_literal: true

require 'rails_helper'

describe Serializers::Admission, type: :model do
  let(:user) { create(:user, :user_with_order) }
  let(:hold_daily_schedule) { create(:hold_daily_schedule) }
  let(:ticket) { user.tickets.first }
  let(:admission_data) { described_class.create(ticket, user) }

  before do
    ticket.update(current_ticket_reserve_id: ticket.ticket_reserves.first.id)
  end

  it 'idにticktのqr_ticket_idが返ってくること' do
    expect(admission_data.id).to eq ticket.qr_ticket_id
  end

  it 'user_idにuserのqr_user_idが表示されること' do
    expect(admission_data.user_id).to eq ticket.user.qr_user_id
  end

  it 'statusは0が表示されること' do
    expect(admission_data.status).to eq 0
  end

  it 'created_atはticketのcreated_atが表示されること' do
    expect(admission_data.created_at).to eq ticket.created_at.iso8601
  end

  it 'updated_atはticketのupdated_atが表示されること' do
    expect(admission_data.updated_at).to eq ticket.updated_at.iso8601
  end

  it 'seat_type_nameはticketのseat_typeのnameが表示されること' do
    expect(admission_data.ticket[:seat_type_name]).to eq ticket.coordinate_seat_type_name
  end

  it 'seat_numberはticketの座席番号が表示されること' do
    expect(admission_data.ticket[:seat_number]).to eq ticket.coordinate_seat_number
  end

  it 'seat_type_optionはticketのoptionのtitleが表示されること' do
    expect(admission_data.ticket[:seat_type_option]).to eq ticket.ticket_reserves.first.seat_type_option.title
  end

  context 'hold.time_zoneが1のとき' do
    before { ticket.hold_daily_schedule.hold.update(time_zone: 1) }

    context 'daily_noがamの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :am) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が11:00で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 11:00')
      end
    end

    context 'daily_noがpmの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :pm) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が16:30で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 16:30')
      end
    end
  end

  context 'hold.time_zoneが2のとき' do
    before { ticket.hold_daily_schedule.hold.update(time_zone: 2) }

    context 'daily_noがamの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :am) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が10:00で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 10:30')
      end
    end

    context 'daily_noがpmの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :pm) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が16:00で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 16:00')
      end
    end
  end

  context 'hold.time_zoneが3のとき' do
    before { ticket.hold_daily_schedule.hold.update(time_zone: 3) }

    context 'daily_noがamの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :am) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が13:30で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 13:30')
      end
    end

    context 'daily_noがpmの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :pm) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が17:50で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 17:50')
      end
    end
  end

  context 'hold.time_zoneが4のとき' do
    before { ticket.hold_daily_schedule.hold.update(time_zone: 4) }

    context 'daily_noがamの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :am) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が12:00で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 12:00')
      end
    end

    context 'daily_noがpmの場合' do
      before { ticket.hold_daily_schedule.update(daily_no: :pm) }

      it 'hold_datetimeはticketのhold_dailyのevent_dateの時間が16:20で表示されること' do
        expect(admission_data.ticket[:hold_datetime]).to eq ticket.hold_daily.event_date.strftime('%Y-%m-%d 16:20')
      end
    end
  end
end
