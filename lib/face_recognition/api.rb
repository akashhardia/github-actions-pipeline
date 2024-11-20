# frozen_string_literal: true

module FaceRecognition
  # 250 platform api fetcher
  class Api < Credential
    class << self
      # 顔認証情報を削除する
      def delete_face_recognition(ticket_id)
        request_params = "ticket_id=#{ticket_id}"
        get_api_response('/tickets', request_params, JSON.dump(ticket_id))
      end

      private

      def get_api_response(api_url, request_params, body)
        request_url = api_host_url + api_url + '?' + request_params
        HTTParty.delete(request_url, headers: api_request_headers(body))
      end

      def api_host_url
        "https://#{FaceRecognition::Credential.api_host}"
      end

      def api_request_headers(body)
        header = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), FaceRecognition::Credential.secret_key, body)
        {
          'X-AIKeirin-Signature' => header
        }
      end
    end
  end
end
