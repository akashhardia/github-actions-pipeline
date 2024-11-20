# frozen_string_literal: true

module Sixgram
  # sixgramの認証情報呼び出し
  class Credential
    class << self
      def account_api_server
        "https://#{CredentialHelper.sixgram[:account_api_host]}"
      end

      def payment_api_server
        "https://#{CredentialHelper.sixgram[:payment_api_host]}"
      end

      def client_id
        CredentialHelper.sixgram[:client_id].to_s
      end

      def secret_base16
        CredentialHelper.sixgram[:secret_base16]
      end

      def secret_base64
        CredentialHelper.sixgram[:secret_base64]
      end

      def client_auth_base_uri
        "#{account_api_server}/client_auth/api/"
      end

      def user_auth_base_uri
        "#{account_api_server}/user_auth/api/"
      end

      def payments_auth_base_uri
        "#{payment_api_server}/user_auth/api/"
      end
    end
  end
end
