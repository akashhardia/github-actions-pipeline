# frozen_string_literal: true

# MIXI Mで無効なアカウントを弾く
class NgUserError < CustomError
  http_status :forbidden
  code 'ng_user_error'
end
