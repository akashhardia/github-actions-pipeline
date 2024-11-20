# frozen_string_literal: true

# SixgramApiの致命的なエラー
class FatalSixgramApiError < CustomError
  http_status :internal_server_error
  code 'fatal_sixgram_api_error'
end
