# frozen_string_literal: true

module FaceRecognition
  # FaceRecognition api fetcher (mock)
  class ApiMock < Credential
    class << self
      # 顔認証情報を削除する
      def delete_face_recognition(ticket_id)
        Response.new(ticket_id)
      end

      private

      def get_api_response(api_url, request_params)
        request_url = api_host_url + api_url + '?' + request_params
        HTTParty.get(request_url, headers: api_request_headers)
      end

      def api_host_url
        "https://#{FaceRecognition::Credential.api_host}"
      end

      def api_request_headers
        {
          'X-AIKeirin-Signature' => 'header'
        }
      end
    end

    # レスポンスのクラス
    class Response
      def initialize(ticket_id)
        @ticket_id = ticket_id
      end

      def ok?
        @ticket_id == '1'
      end

      def unauthorized?
        @ticket_id == '2'
      end

      def not_found?
        @ticket_id != '1' && @ticket_id != '2'
      end
    end
  end
end
