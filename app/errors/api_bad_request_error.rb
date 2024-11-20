# frozen_string_literal: true

# BadRequest汎用エラー
class ApiBadRequestError < CustomError
  http_status :bad_request
  code 'bad_request'
end
