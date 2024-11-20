# frozen_string_literal: true

# Mockのレスポンス定義
module MockResponse
  def response_result(succeed)
    { ok?: succeed }
  end

  def ok
    { **response_result(true), response: { code: '200' } }
  end

  def bad_request
    { **response_result(false), response: { code: '400' } }
  end

  def unauthorized
    { **response_result(false), response: { code: '401' } }
  end

  def forbidden
    { **response_result(false), response: { code: '403' } }
  end

  def not_found
    { **response_result(false), response: { code: '404' } }
  end

  def unprocessable_entity
    { **response_result(false), response: { code: '422' } }
  end

  def internal_server_error
    { **response_result(false), response: { code: '500' } }
  end

  def service_unavailable
    { **response_result(false), response: { code: '503' } }
  end
end
