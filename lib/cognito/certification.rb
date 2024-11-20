# frozen_string_literal: true

module Cognito
  # JWTの検証
  # Cognito以外でも使うかも
  class Certification < Credential
    ALGORITHM = 'RS256'

    class << self
      def verify_jwt!(jwt)
        _pre_payload, header = JWT.decode(jwt, nil, false)

        kid = header['kid']

        public_key = generate_pub_key(kid)

        valid_option = {
          algorithm: ALGORITHM,
          verify_aud: true,
          verify_iss: true,
          verify_iat: true,
          aud: client_id,
          iss: iss
        }

        # 再デコードできたら検証OK
        payload, _header = JWT.decode(jwt, public_key, true, valid_option)

        payload['sub']
      end

      def iss
        "https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}"
      end

      def generate_pub_key(kid)
        pub_key_url = iss + '/.well-known/jwks.json'

        response = HTTParty.get(pub_key_url)

        jwk = response['keys'].find { |j| j['kid'] == kid }
        modulus = openssl_bn(jwk['n'])
        exponent = openssl_bn(jwk['e'])

        sequence = OpenSSL::ASN1::Sequence.new(
          [OpenSSL::ASN1::Integer.new(modulus),
           OpenSSL::ASN1::Integer.new(exponent)]
        )

        OpenSSL::PKey::RSA.new(sequence.to_der)
      end

      def openssl_bn(code)
        code += '=' * (4 - code.size % 4) if code.size % 4 != 0
        decoded = Base64.urlsafe_decode64 code
        unpacked = decoded.unpack1('H*')
        OpenSSL::BN.new unpacked, 16
      end
    end
  end
end
