# frozen_string_literal: true

# 250PF API関連エラー
class PfApiError < CustomError
  http_status :bad_request
  code 'pf_api_error'
end
