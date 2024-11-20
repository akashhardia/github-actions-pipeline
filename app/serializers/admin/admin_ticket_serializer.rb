# frozen_string_literal: true

module Admin
  # 譲渡IDなどの秘匿情報を追加で取得する
  class AdminTicketSerializer < TicketSerializer
    attributes :transfer_uuid, :qr_ticket_id, :user_id, :unit_type, :unit_name

    def unit_type
      master_seat_unit&.seat_type
    end

    def unit_name
      master_seat_unit&.unit_name
    end

    private

    def master_seat_unit
      @master_seat_unit ||= object.master_seat_unit
    end
  end
end
