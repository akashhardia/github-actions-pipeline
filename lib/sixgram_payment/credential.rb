# frozen_string_literal: true

module SixgramPayment
  # sixgram paymentの認証情報呼び出し
  class Credential
    class << self
      def payment_uri
        "https://#{CredentialHelper.sixgram_payment[:api_host]}"
      end

      def public_key
        CredentialHelper.sixgram_payment[:public_key]
      end

      def secret_key
        CredentialHelper.sixgram_payment[:secret_key]
      end
    end
  end
end
