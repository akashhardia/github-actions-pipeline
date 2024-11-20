# frozen_string_literal: true

module MixiM
  # mixi_mの認証情報呼び出し
  class Credential
    class << self
      def account_api_server
        "https://#{CredentialHelper.mixi_m[:account_api_host]}"
      end

      def client_id
        CredentialHelper.mixi_m[:client_id].to_s
      end

      def secret_base64
        CredentialHelper.mixi_m[:secret_base64]
      end

      def authorize_uri
        "#{account_api_server}/authorize"
      end

      def user_info_uri
        "#{account_api_server}/api/oidc/userinfo"
      end

      def token_uri
        "#{account_api_server}/api/oidc/token"
      end
    end
  end
end
