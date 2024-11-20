# frozen_string_literal: true

module Admin
  # 管理画面用所持チケット一覧Serializer
  class TicketReserveIndexSerializer < ActiveModel::Serializer
    attributes :id, :qr_ticket_id, :transfer_status, :event_date, :daily_no, :hold_name_jp, :admission_time,
               :ticket_status, :updated_at, :transfer_status, :ticket_id, :option_title

    delegate :hold_name_jp, :daily_no, :event_date, to: :hold_daily_schedule

    def transfer_status
      return 'done' if object.transfer_at.present? # 譲渡完了
      return 'doing' if ticket.transfer_uuid.present? # 譲渡中

      'notDone' # 譲渡処理をしていない
    end

    # 入場開始時間
    def admission_time
      object.order.seat_sale.admission_available_at.strftime('%H:%M')
    end

    def ticket_status
      ticket.ticket_logs.result_true.last&.result_status || 'before_enter'
    end

    def option_title
      object.seat_type_option.present? ? object.seat_type_option.title : nil
    end

    delegate :id, to: :ticket, prefix: true

    delegate :qr_ticket_id, to: :ticket

    private

    def hold_daily_schedule
      object.order.seat_sale.hold_daily_schedule
    end

    def ticket
      object.ticket
    end
  end
end
