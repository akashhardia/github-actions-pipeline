# frozen_string_literal: true

# ログイン必須のエラー
class LoginRequiredError < CustomError
  http_status :unauthorized
  code 'login_required'
end
