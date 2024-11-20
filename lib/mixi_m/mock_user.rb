# frozen_string_literal: true

module MixiM
  # Mock動作のみ
  # APIでNG系のレスポンスが返ってくるユーザーをここで定義する
  class MockUser < Certification
    extend MockResponse

    class << self
      def find_mock(method_name, sixgram_id)
        response = mock_response(sixgram_id)[method_name][sixgram_id].presence || mock_response(sixgram_id)[method_name][:default]

        JSON.parse(response.to_json, object_class: OpenStruct)
      end

      private

      def mock_response(sixgram_id)
        {
          get_token:
            {
              default: default_auth_token(sixgram_id),
              # 必要なパラメーターが不足
              '07000010000' => { **bad_request, error: 'invalid_request' },
              # 必要なパラメーターが不正
              '07000010001' => { **bad_request, error: 'invalid_grant' },
              # クライアント認証に失敗
              '07000010002' => { **unauthorized, error: 'invalid_client' },
              # 予期せぬエラー
              '07000019999' => { **internal_server_error, error: 'internal_server_error' }
            },
          get_user_info:
            {
              default: { **ok, 'birthday' => '2000-01-01T00:00:00+00:00', 'email' => 'example@example.com', 'family_name' => '競輪テスト', 'family_name_kana' => 'ケイリンテスト', 'given_name' => '太郎テスト', 'given_name_kana' => 'タロウテスト', 'phone_number' => sixgram_id },
              # 誕生日が不足
              '07000020000' => { **ok, 'birthday' => nil, 'email' => 'example@example.com', 'family_name' => '競輪テスト', 'family_name_kana' => 'ケイリンテスト', 'given_name' => '太郎テスト', 'given_name_kana' => 'タロウテスト', 'phone_number' => sixgram_id },
              # 必要なパラメーターが不足
              '07000020001' => { **bad_request, error: 'invalid_request' },
              # 必要なパラメーターが不正
              '07000020002' => { **bad_request, error: 'invalid_grant' },
              # クライアント認証に失敗
              '07000020003' => { **unauthorized, error: 'invalid_client' },
              # 予期せぬエラー
              '07000029999' => { **internal_server_error, error: 'internal_server_error' }
            },
          reget_token:
            {
              default: default_refreshed_auth_token(sixgram_id),
              # 必要なパラメーターが不足
              '07000030000' => { **bad_request, error: 'invalid_request' },
              # 必要なパラメーターが不正
              '07000030001' => { **bad_request, error: 'invalid_grant' },
              # クライアント認証に失敗
              '07000030002' => { **unauthorized, error: 'invalid_client' },
              # 予期せぬエラー
              '07000039999' => { **internal_server_error, error: 'internal_server_error' }
            }
        }
      end

      def default_auth_token(sixgram_id)
        {
          **ok,
          "access_token": generate_user_auth_token(sixgram_id),
          "expires_in": 3600,
          "id_token": generate_user_auth_token(sixgram_id),
          "legacy_auth_token": generate_user_auth_token(sixgram_id),
          "refresh_token": 'refresh_token',
          "scope": 'openid profile email phone address offline_access',
          "token_type": 'Bearer'
        }
      end

      def generate_user_auth_token(sixgram_id)
        iat = Time.zone.now.to_i
        client_id = client_id.to_s
        token_id = "#{sixgram_id}-#{client_id}-#{iat}"

        payload =
          {
            iss: 'https://rima.ratel.com',
            aud: client_id,
            sub: sixgram_id,
            jti: token_id,
            iat: iat,
            exp: (Time.zone.now + 10.years).to_i,
            scopes: [],
            token_id: token_id,
            token_secret: SecureRandom.alphanumeric(43),
            nonce: '123',
            phone_number: sixgram_id
          }

        headers =
          {
            alg: 'HS256',
            kid: 'user_auth_token',
            typ: 'JWT'
          }

        secret = [CredentialHelper.sixgram[:secret_base16]].pack('H*')

        JWT.encode(payload, secret, headers[:alg], headers)
      end

      def default_refreshed_auth_token(sixgram_id)
        {
          **ok,
          "access_token": generate_user_auth_token(sixgram_id),
          "expires_in": 3600,
          "id_token": generate_user_auth_token(sixgram_id),
          "legacy_auth_token": nil,
          "refresh_token": generate_user_auth_token(sixgram_id),
          "scope": 'openid profile email phone address offline_access',
          "token_type": 'Bearer'
        }
      end
    end
  end
end
