# frozen_string_literal: true

module Cognito
  # cognitoの認証情報呼び出し
  class Credential
    class << self
      def region
        CredentialHelper.cognito[:region]
      end

      def client_id
        CredentialHelper.cognito[:client_id]
      end

      def user_pool_id
        CredentialHelper.cognito[:user_pool_id]
      end

      def access_key_id
        CredentialHelper.cognito[:access_key_id]
      end

      def secret_access_key
        CredentialHelper.cognito[:secret_access_key]
      end
    end
  end
end
