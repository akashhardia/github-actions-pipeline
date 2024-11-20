# frozen_string_literal: true

module Platform
  # 250Platformの認証情報呼び出し
  class Credential
    class << self
      def api_host
        CredentialHelper.pf_api[:api_host]
      end

      def api_id
        CredentialHelper.pf_api[:api_id]
      end

      def api_key
        CredentialHelper.pf_api[:api_key]
      end
    end
  end
end
