# frozen_string_literal: true

module MixiM
  # JWTの作成
  class Certification < Credential
    ALGORITHM = 'HS256'
    CLIENT_JWT_EXP = 1.month
    ACCESS_JWT_EXP = 15.minutes
    AUDIENCE = "https://#{Rails.application.credentials.mixi_m[:account_api_host]}/api/oidc/token"

    class << self
      def create_client_assertion
        payload = {
          iss: client_id,
          sub: client_id,
          aud: AUDIENCE,
          exp: (Time.zone.now + ACCESS_JWT_EXP).to_i,
          jti: SecureRandom.uuid
        }

        JWT.encode(payload, secret_base64, ALGORITHM, { typ: 'JWT' })
      end

      def code_challenge(code_verifire)
        Base64.urlsafe_encode64(OpenSSL::Digest::SHA256.digest(code_verifire), padding: false)
      end
    end
  end
end
