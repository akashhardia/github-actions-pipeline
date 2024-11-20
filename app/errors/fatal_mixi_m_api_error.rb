# frozen_string_literal: true

# SixgramApiの致命的なエラー
class FatalMixiMApiError < CustomError
  http_status :internal_server_error
  code 'fatal_mixi_m_api_error'
end
