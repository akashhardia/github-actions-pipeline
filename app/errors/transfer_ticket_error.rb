# frozen_string_literal: true

# 譲渡関連エラー
class TransferTicketError < CustomError
  http_status :bad_request
  code 'transfer_ticket_error'
end
