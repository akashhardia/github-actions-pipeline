# frozen_string_literal: true

# Sixgram決済上の致命的なエラー
class FatalSixgramPaymentError < CustomError
  http_status :internal_server_error
  code 'fatal_sixgram_payment_error'
end
