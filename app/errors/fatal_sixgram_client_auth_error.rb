# frozen_string_literal: true

# クライアント認証エラー
class FatalSixgramClientAuthError < CustomError
  http_status :internal_server_error
  code 'invalid_sixgram_client_auth_error'
end
