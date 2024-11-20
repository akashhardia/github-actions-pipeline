# frozen_string_literal: true

# ユーザーが退会済みのエラー
class UnsubscribedUserError < CustomError
  http_status :forbidden
  code 'unsubscribed_user_error'
end
