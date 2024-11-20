# frozen_string_literal: true

module Sixgram
  # Mock動作のみ
  # APIでNG系のレスポンスが返ってくるユーザーをここで定義する
  class MockUser < Certification
    extend MockResponse

    MOCK_PAYMENT_PATH = 'http://localhost:3000/sales/test_views/charge_authorization'

    class << self
      def find_mock(method_name, sixgram_id)
        response = mock_response(sixgram_id)[method_name][sixgram_id].presence || mock_response(sixgram_id)[method_name][:default]

        JSON.parse(response.to_json, object_class: OpenStruct)
      end

      private

      def mock_response(sixgram_id) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        random_id = SecureRandom.uuid
        {
          send_sms_auth_code:
            {
              default: { **ok, verify_token: generate_verify_session_token(sixgram_id) },
              # 必要なパラメーターが不足
              '09000010005' => { **bad_request, error: 'invalid_request' },
              # 電話番号が不正
              '09000010006' => { **bad_request, error: 'invalid_phone_number' },
              # app_hash のフォーマットが不正
              '09000010007' => { **bad_request, error: 'invalid_app_hash_format' },
              # 認証コード無効化回数の上限に達した
              '09000010008' => { **forbidden, error: 'lockout_env' },
              # 認証コード送信回数の上限に達した
              '09000010009' => { **forbidden, error: 'lockout_send_auth_code' },
              # なんらかの理由でSMSの送信に失敗した
              '09000010010' => { **internal_server_error, error: 'send_sms_failed' },
              # 電話番号単位のSMS送信リクエストの上限に達した
              '09000010011' => { **service_unavailable, error: 'send_sms_phone_number_limit_exceeded' },
              # SMS送信リクエストの上限に達した
              '09000010012' => { **service_unavailable, error: 'send_sms_limit_exceeded' }
            },
          verify_sms_auth_code:
            {
              default: { **ok, auth_token: generate_user_auth_token(sixgram_id) },
              # 必要なパラメーターが不足
              '09000010013' => { **bad_request, error: 'invalid_request' },
              # verify_token が不正
              '09000010014' => { **bad_request, error: 'invalid_verify_token' },
              # auth_message のフォーマットが異なる
              '09000010015' => { **bad_request, error: 'invalid_auth_message' },
              # auth_code が既に認証に使われている
              '09000010016' => { **bad_request, error: 'already_used_auth_code' },
              # auth_code が期限切れである
              '09000010017' => { **bad_request, error: 'expired_auth_code' },
              # auth_code が間違っている、不正な文字が使われている、ダミートークンを使ったリクエストである
              '09000010018' => { **bad_request, error: 'invalid_auth_code' },
              # 認証コード無効化回数の上限に達した
              '09000010019' => { **forbidden, error: 'lockout_env' },
              # 試行回数の上限に達したため認証コードが無効化された
              '09000010020' => { **forbidden, error: 'revoked_auth_code' },
              # 生年月日の確認が必要な時
              '09000010021' => { **unauthorized, error: 'birthdate_verification_required' },
              # 生年月日を登録していないユーザー
              '09000010022' => { **forbidden, error: 'birthdate_verification_unavailable' },
              # 既に3回生年月日確認を失敗しているユーザー
              '09000010023' => { **forbidden, error: 'lockout_birthdate_verification' }
            },
          get_account_level:
            {
              default: { **ok, 'antisocial_check' => 'clear', 'level' => 4, 'flags' => %w[nickname name birthdate antisocial_forces_check credit_card] },
              # 反社チェックに引っかかるユーザー
              '09000010002' => { **ok, antisocial_check: 'marked', level: 4, flags: %w[nickname name birthdate credit_card] },
              # 反社チェックに失敗するユーザー
              '09000010003' => { **ok, antisocial_check: 'failure', level: 4, flags: %w[nickname name birthdate credit_card] },
              # トークンが不正なユーザー
              '09000010004' => { **unauthorized, error: 'invalid_token', error_description: 'invalid request_hash', user_id: '09000010004' },
              # BANされたユーザー
              '09000020002' => { **ok, 'antisocial_check' => 'clear', 'level' => 4, 'flags' => %w[nickname name birthdate credit_card ban] },
              # 共通エラー アクセストークンが有効期限切れで失効している。サーバーの時間と大幅にずれている可能性がある
              '09000020003' => { **unauthorized, error: 'token_expired', error_description: 'token_expired', user_id: '09000020000' },
              # 共通エラー ユーザー認証トークンが有効期限切れで失効している。再取得を行う必要がある
              '09000020004' => { **unauthorized, error: 'auth_token_expired', error_description: 'auth_token_expired', user_id: '09000020001' },
              # 共通エラー 存在しない、あるいは無効にされた認証情報。再ログインで有効な認証情報を取得できる可能性がある
              '09000020005' => { **unauthorized, error: 'invalid_user', error_description: 'invalid_user', user_id: '09000020002' }
            },
          get_personal_data:
            {
              default: { **ok, 'address_line_1' => nil, 'address_line_2' => nil, 'address_line_3' => nil, 'birthdate' => nil, 'family_kana' => nil, 'family_name' => nil, 'given_kana' => nil, 'given_name' => nil, 'post_code' => nil, 'prefecture' => nil, 'user_id' => nil },
              # データに不足なし
              '09000010121' => { **ok, 'address_line_1' => nil, 'address_line_2' => nil, 'address_line_3' => nil, 'birthdate' => '20210101', 'family_kana' => 'ケイリン', 'family_name' => '競輪', 'given_kana' => 'タロウ', 'given_name' => '太郎', 'post_code' => nil, 'prefecture' => nil, 'user_id' => sixgram_id },
              # データに不足がある(生年月日が空)
              '09000010122' => { **ok, 'birthdate' => nil, 'family_kana' => 'ケイリン', 'family_name' => '競輪', 'given_kana' => 'タロウ', 'given_name' => '太郎', 'user_id' => '09000010021' },
              # トークンが不正なユーザー
              '09000010004' => { **unauthorized, error: 'invalid_token', error_description: 'invalid request_hash', user_id: '09000010004' }
            },
          get_identification_status:
            {
              # 本人確認状況: 未確認
              default: { **ok, 'error_codes' => [], 'status' => 'not_uploaded', 'updated_at' => 1612105200 },
              # 本人確認状況: 確認中
              '09000010022' => { **ok, 'status' => 'in_progress', 'error_codes' => [], 'updated_at' => 1582703624 },
              # 本人確認状況: 完了
              '09000010023' => { **ok, 'status' => 'approved', 'error_codes' => [], 'updated_at' => 1582703624 },
              # 本人確認状況: 差し戻し
              '09000010024' => { **ok, 'status' => 'rejected', 'error_codes' => %w[unclear_image generic_error], 'updated_at' => 1582703624 },
              # トークンが不正なユーザー
              '09000010004' => { **unauthorized, error: 'invalid_token', error_description: 'invalid request_hash', user_id: '09000010004' }
            },
          post_user_name:
            {
              default: { **ok, 'account_level' => { 'flags' => %w[nickname name birthdate antisocial_forces_check credit_card], 'level' => 4 }, 'family_kana' => 'family_kana', 'family_name' => 'family_name', 'given_kana' => 'given_kana', 'given_name' => 'given_name', 'user_id' => sixgram_id },
              # 不正なパラメーター: 入力が空
              '09000010025' => { **bad_request, error: 'invalid_request', error_description: ['family_kana' => ["can't be blank"], 'family_name' => ["can't be blank"], 'given_kana' => ["can't be blank"], 'given_name' => ["can't be blank"]] },
              # 不正なパラメーター: 入力フォーマットが不正
              '09000010026' => { **unprocessable_entity, error: 'invalid_request', error_description: ['family_kana' => ['has invalid format'], 'given_kana' => ['has invalid format']] },
              # トークンが不正なユーザー
              '09000010004' => { **unauthorized, error: 'invalid_token', error_description: 'invalid request_hash', user_id: '09000010004' }
            },
          post_birthdate:
            {
              default: { **ok, 'account_level' => { 'flags' => %w[nickname name birthdate antisocial_forces_check credit_card], 'level' => 4 }, 'birthdate' => 'birthdate', 'user_id' => sixgram_id },
              # 不正なパラメーター: 入力が空
              '09000010027' => { **bad_request, error: 'invalid_request', error_description: ['birthdate' => ["can't be blank"]] },
              # 不正なパラメーター: 入力フォーマットが不正
              '09000010028' => { **unprocessable_entity, error: 'invalid_request', error_description: ['birthdate' => ['has invalid format']] },
              # トークンが不正なユーザー
              '09000010004' => { **unauthorized, error: 'invalid_token', error_description: 'invalid request_hash', user_id: '09000010004' }
            },
          payment_deposit:
            {
              default: { **ok, authorized: true, charge_id: random_id, get_url: "#{MOCK_PAYMENT_PATH}?charge_id=#{random_id}" },
              '09000010004' => { **unauthorized, error: 'invalid_token', error_description: 'invalid request_hash', user_id: '09000010004' },

              ### 決済時にエラーが発生するcharge_idを発行する
              ### エラー定義はsixgram_payment/mock_paymentを参照してください

              ## charge_status(支払取得時エラー)
              # status: 'processing'
              '09000010029' => { **ok, authorized: false, charge_id: '211111', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=211111" },
              # status: 'failed'
              '09000010030' => { **ok, authorized: false, charge_id: '211112', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=211112" },
              # status: 'canceled'
              '09000010031' => { **ok, authorized: false, charge_id: '211113', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=211113" },
              # authorized: false
              '09000010032' => { **ok, authorized: false, charge_id: '211114', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=211114" },

              ## capture(支払確定時エラー)
              # status: 'processing'
              '09000020032' => { **ok, authorized: false, charge_id: '212111', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=212111" },
              # status: 'failed'
              '09000020033' => { **ok, authorized: false, charge_id: '212112', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=212112" },
              # status: 'canceled'
              '09000020034' => { **ok, authorized: false, charge_id: '212113', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=212113" },
              # status: 'failed' captured: 'false'
              '09000020045' => { **ok, authorized: false, charge_id: '212114', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=212114" },
              # bad_request: 'already_captured'
              '09000020035' => { **ok, authorized: false, charge_id: '412111', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412111" },
              # bad_request: 'already_refunded'
              '09000020036' => { **ok, authorized: false, charge_id: '412112', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412112" },
              # bad_request: 'disputed'
              '09000020037' => { **ok, authorized: false, charge_id: '412113', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412113" },
              # bad_request: 'expired_for_capture'
              '09000020038' => { **ok, authorized: false, charge_id: '412114', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412114" },
              # bad_request: 'card_declined'
              '09000020039' => { **ok, authorized: false, charge_id: '412115', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412115" },
              # not_found: 'resource_not_found'
              '09000020040' => { **ok, authorized: false, charge_id: '412116', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412116" },
              # internal_server_error: 'internal_server_error'
              '09000020099' => { **ok, authorized: false, charge_id: '412199', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=412199" },

              ## refund(返金時エラー)
              # bad_request: already_refunded
              '09000030041' => { **ok, authorized: false, charge_id: '413111', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=413111" },
              # bad_request: disputed
              '09000030042' => { **ok, authorized: false, charge_id: '413112', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=413112" },
              # bad_request: expired_for_refund
              '09000030043' => { **ok, authorized: false, charge_id: '413113', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=413113" },
              # bad_request: resource_not_found
              '09000030044' => { **ok, authorized: false, charge_id: '413114', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=413114" },

              ## 正常系（charge_id固定）
              '09000040029' => { **ok, authorized: true, charge_id: '414111', get_url: "#{MOCK_PAYMENT_PATH}?charge_id=414111" }
            },
          get_migration_validate:
            {
              default: { **ok, 'migration_required': false },
              # migrationが必要な場合
              '09000050001' => { **ok, 'migration_required': true, "migration_info": { "birthdate": '19990101' } },
              # 自動的に解決できない競合が発生しているユーザー
              '09000050002' => { **forbidden, error: 'need_contact' },
              # 共通エラー 存在しない、あるいは無効にされた認証情報。再ログインで有効な認証情報を取得できる可能性がある
              '09000050003' => { **unauthorized, error: 'invalid_user', error_description: 'invalid_user', user_id: '09000050003' },
              # migrationが必要な場合(全ての項目)
              '09000050004' => { **ok, 'migration_required': true, "migration_info": { 'name': { 'family_name': '三串', 'given_name': '一郎', 'family_kana': 'ミクシ', 'given_kana': 'イチロウ' }, 'birthdate': '19990101', 'payee_bank': [{ 'bank_code': '0001', 'branch_code': '00123', 'account_type': 'saving', 'account_number': '1234567', 'account_name': 'ミクシイチロウ' }, { 'bank_code': '0009', 'branch_code': '00123', 'account_type': 'saving', 'account_number': '1234567', 'account_name': 'ミクシイチロウ' }], 'id_proofing_status': true } }

            },
          post_migration_apply:
            {
              default: { **ok },
              # 移行済みユーザー
              '09000060001' => { **bad_request, error: 'already_migrated' },
              # 自動的に解決できない競合が発生しているユーザー
              '09000060002' => { **forbidden, error: 'need_contact' }
            }
        }
      end

      def generate_verify_session_token(sixgram_id)
        # mockでは電話番号 == sixgram_idとする
        phone_number = sixgram_id.dup
        phone_number[0] = '81'
        intl_phone_number = phone_number

        payload =
          {
            auth_code_id: SecureRandom.random_number(1 << 64),
            intl_phone_number: intl_phone_number,
            user_hash: Base64.strict_encode64(intl_phone_number),
            usage: 'signin'
          }

        headers = {
          alg: 'HS256',
          kid: 'verify_201808',
          typ: 'JWT'
        }

        secret = Base64.decode64(SecureRandom.uuid)
        JWT.encode(payload, secret, headers[:alg], headers)
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
            token_secret: SecureRandom.alphanumeric(43)
          }

        headers =
          {
            alg: 'HS256',
            kid: 'user_auth_token',
            typ: 'JWT'
          }

        secret = [secret_base16].pack('H*')

        JWT.encode(payload, secret, headers[:alg], headers)
      end
    end
  end
end
