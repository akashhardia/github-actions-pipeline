# frozen_string_literal: true

module Sixgram
  # JWTの作成
  class Certification < Credential
    ALGORITHM = 'HS256'
    CLIENT_JWT_EXP = 1.month
    ACCESS_JWT_EXP = 10.minutes
    AUDIENCE = 'https://rima.ratel.com'

    class << self
      def verify_jwt!(jwt)
        key = [secret_base16].pack('H*')
        payload, _header = JWT.decode(jwt, key)
        payload
      end

      def generate_client_jwt
        secret = [secret_base16].pack('H*')

        payload = {
          iss: client_id,
          aud: AUDIENCE,
          sub: client_id,
          exp: (Time.zone.now + CLIENT_JWT_EXP).to_i,
          iat: Time.zone.now.to_i,
          jti: SecureRandom.uuid
        }

        JWT.encode(payload, secret, ALGORITHM)
      end

      def generate_access_jwt(user_auth_token, request_method)
        user_auth_payload, _header = JWT.decode(user_auth_token, nil, false)

        secret = Base64.urlsafe_decode64(user_auth_payload['token_secret'])

        request_hash = Digest::SHA256.hexdigest(request_method)

        payload = {
          iss: client_id,
          aud: AUDIENCE,
          sub: user_auth_payload['sub'],
          exp: (Time.zone.now + ACCESS_JWT_EXP).to_i,
          iat: Time.zone.now.to_i,
          token_id: user_auth_payload['token_id'],
          request_hash: request_hash
        }

        JWT.encode(payload, secret, ALGORITHM)
      end
    end
  end
end
