# frozen_string_literal: true

# ユーザー認証エラー
class InvalidCognitoTokenError < CustomError
  http_status :unauthorized
  code 'invalid_cognito_token_error'
end
