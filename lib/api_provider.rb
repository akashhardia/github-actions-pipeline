# frozen_string_literal: true

# ApiProvider.cognito.get_token のように使う
module ApiProvider
  class << self
    def platform
      Rails.env.test? ? Platform::ServiceMock : Platform::Service
    end

    def cognito
      Cognito::Service
    end

    def face_recognition
      Rails.env.development? || Rails.env.test? ? FaceRecognition::ApiMock : FaceRecognition::Api
    end

    def new_system
      NewSystem::Api
    end

    def api_log(request_params, result)
      # request_paramsをjson化
      request_params_json = request_params.scan(/(\w+)=(\w+)/).map { |k, v| [k.to_sym, v] }.to_h.to_json # rubocop:disable Style/HashTransformKeys

      ExternalApiLog.create(
        host: result.request.path.host,
        path: result.request.path.path,
        request_params: request_params_json,
        response_http_status: result.response.code.to_i,
        response_params: result.body
      )
    end
  end
end
