# frozen_string_literal: true

# ユーザー認証エラー
class InvalidMixiMUserAuthError < CustomError
  http_status :unauthorized
  code 'invalid_mixi_m_user_auth_error'
end
