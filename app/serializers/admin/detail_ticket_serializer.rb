# frozen_string_literal: true

module Admin
  # チケットdetail用Serializer
  class DetailTicketSerializer < TicketReserveSerializer
    attributes :user_id, :status, :created_at, :updated_at, :admission_disabled_at

    def status
      object.ticket_logs.result_true.last&.result_status || 'before_enter'
    end
  end
end
