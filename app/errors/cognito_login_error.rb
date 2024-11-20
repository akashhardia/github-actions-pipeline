# frozen_string_literal: true

# jwt取得時のエラー
class CognitoLoginError < CustomError
  http_status :bad_request
  code 'cognito_login_error'
end
