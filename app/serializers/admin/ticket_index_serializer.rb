# frozen_string_literal: true

module Admin
  # チケット照会の一覧用
  class TicketIndexSerializer < ActiveModel::Serializer
    attributes :id, :qr_ticket_id, :hold_name_jp, :daily_no, :event_date, :admission_time, :ticket_status, :updated_at, :transfer_status, :option_title

    def hold_name_jp
      object.seat_sale.hold_daily.hold.hold_name_jp
    end

    def event_date
      object.seat_sale.hold_daily.event_date
    end

    def daily_no
      HoldDailySchedule::DAILY_NO[object.seat_sale.hold_daily_schedule.daily_no.to_sym]
    end

    # 入場開始時間
    def admission_time
      object.seat_sale.admission_available_at.strftime('%H:%M')
    end

    def ticket_status
      object.ticket_logs.result_true.last&.result_status || 'before_enter'
    end

    def transfer_status
      return 'notDone' if ticket_reserve.blank? # チケット予約がない場合は、譲渡申請なし
      return 'doing' if object.transfer_uuid.present? # 譲渡中

      'notDone' # 譲渡申請なし
    end

    def option_title
      ticket_reserve&.seat_type_option.present? ? ticket_reserve.seat_type_option.title : nil
    end

    private

    # 対象のチケット予約
    def ticket_reserve
      @ticket_reserve ||= object.current_ticket_reserve || object.ticket_reserves.not_transfer_ticket_reserve.filter_ticket_reserves&.last
    end
  end
end
