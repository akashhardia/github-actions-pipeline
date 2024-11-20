# frozen_string_literal: true

# ユーザー認証エラー
class InvalidSixgramUserAuthError < CustomError
  http_status :unauthorized
  code 'invalid_sixgram_user_auth_error'
end
