# frozen_string_literal: true

require 'rails_helper'

describe Sixgram::Service do
  describe '#send_sms_auth_code!' do
    subject(:send_sms_auth_code) { described_class.send_sms_auth_code(phone_number) }

    context 'デフォルト' do
      let(:phone_number) { '09012345678' }

      it '電話番号検証セッションtokenが返ってくること' do
        token = send_sms_auth_code
        payload, _header = JWT.decode(token, nil, false)
        expect(payload['usage']).to eq('signin')
        expect(payload['intl_phone_number']).to eq('819012345678')
      end
    end

    context '必要なパラメーターが不足 invalid_request' do
      let(:phone_number) { '09000010005' }

      it '400エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.send_sms_auth_code.invalid_request'))
      end
    end

    context '電話番号が不正 invalid_phone_number' do
      let(:phone_number) { '09000010006' }

      it '400エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.send_sms_auth_code.invalid_phone_number'))
      end
    end

    context 'app_hash のフォーマットが不正 invalid_app_hash_format' do
      let(:phone_number) { '09000010007' }

      it '500エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(FatalSixgramApiError, 'エラーが発生しました')
      end
    end

    context '認証コード無効化回数の上限に達した lockout_env' do
      let(:phone_number) { '09000010008' }

      it '400エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.send_sms_auth_code.lockout_env'))
      end
    end

    context '認証コード送信回数の上限に達した lockout_send_auth_code' do
      let(:phone_number) { '09000010009' }

      it '400エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.send_sms_auth_code.lockout_send_auth_code'))
      end
    end

    context 'なんらかの理由でSMSの送信に失敗した send_sms_failed' do
      let(:phone_number) { '09000010010' }

      it '500エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(FatalSixgramApiError, 'エラーが発生しました')
      end
    end

    context '電話番号単位のSMS送信リクエストの上限に達した send_sms_phone_number_limit_exceeded' do
      let(:phone_number) { '09000010011' }

      it '400エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.send_sms_auth_code.send_sms_phone_number_limit_exceeded'))
      end
    end

    context 'SMS送信リクエストの上限に達した send_sms_limit_exceeded' do
      let(:phone_number) { '09000010012' }

      it '400エラーが発生すること' do
        expect { send_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.send_sms_auth_code.send_sms_limit_exceeded'))
      end
    end
  end

  describe '#verify_sms_auth_code!', :sales_jwt_mock do
    subject(:verify_sms_auth_code) { described_class.verify_sms_auth_code(verify_token, '0000') }

    let(:verify_token) do
      dup_phone_number = phone_number.dup
      dup_phone_number[0] = '81'
      intl_phone_number = dup_phone_number

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

    context 'デフォルト' do
      let(:phone_number) { '08012345678' }

      it '電話番号検証セッションtokenが返ってくること' do
        token = verify_sms_auth_code
        payload, _header = JWT.decode(token, nil, false)
        expect(payload['sub']).to eq(phone_number)
      end
    end

    context '必要なパラメーターが不足 invalid_request' do
      let(:phone_number) { '09000010013' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.invalid_request'))
      end
    end

    context 'verify_tokenが不正 invalid_verify_token' do
      let(:phone_number) { '09000010014' }

      it '再認証エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(LoginRequiredError, I18n.t('api_errors.sixgram.verify_sms_auth_code.invalid_verify_token'))
      end
    end

    context 'auth_messageのフォーマットが異なる invalid_auth_message' do
      let(:phone_number) { '09000010015' }

      it '500エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(FatalSixgramApiError, 'エラーが発生しました')
      end
    end

    context 'auth_codeが既に認証に使われている already_used_auth_code' do
      let(:phone_number) { '09000010016' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.already_used_auth_code'))
      end
    end

    context 'auth_codeが期限切れである expired_auth_code' do
      let(:phone_number) { '09000010017' }

      it '再認証エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(LoginRequiredError, I18n.t('api_errors.sixgram.verify_sms_auth_code.expired_auth_code'))
      end
    end

    context 'auth_codeが間違っている、不正な文字が使われている、ダミートークンを使ったリクエストである invalid_auth_code' do
      let(:phone_number) { '09000010018' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.invalid_auth_code'))
      end
    end

    context '認証コード無効化回数の上限に達した lockout_env' do
      let(:phone_number) { '09000010019' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.lockout_env'))
      end
    end

    context '認証コード無効化回数の上限に達した revoked_auth_code' do
      let(:phone_number) { '09000010020' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.revoked_auth_code'))
      end
    end

    context '生年月日の確認が必要な時 birthdate_verification_required' do
      let(:phone_number) { '09000010021' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.birthdate_verification_required'))
      end
    end

    context '生年月日を登録していないユーザー birthdate_verification_unavailable' do
      let(:phone_number) { '09000010022' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.birthdate_verification_unavailable'))
      end
    end

    context '既に３回生年月日確認を失敗しているユーザー lockout_birthdate_verification' do
      let(:phone_number) { '09000010023' }

      it '400エラーが発生すること' do
        expect { verify_sms_auth_code }.to raise_error(CustomError, I18n.t('api_errors.sixgram.verify_sms_auth_code.lockout_birthdate_verification'))
      end
    end
  end

  describe '#get_account_level', :sales_jwt_mock do
    subject(:get_account_level) { described_class.get_account_level(sixgram_access_token) }

    context 'デフォルト 反社チェッククリアユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it '反社チェッククリアのレスポンスが返ってくる' do
        expect(get_account_level['antisocial_check']).to eq('clear')
      end
    end

    context 'トークンが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

      it 'エラーが発生すること' do
        expect { get_account_level }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '反社チェックに引っかかるユーザー' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010002' }

      it '反社チェッククリアのレスポンスが返ってくる' do
        expect(get_account_level['antisocial_check']).to eq('marked')
      end
    end

    context '反社チェックで失敗するユーザー' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010003' }

      it '反社チェッククリアのレスポンスが返ってくる' do
        expect(get_account_level['antisocial_check']).to eq('failure')
      end
    end

    context 'BANされたユーザー' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000020002' }

      it '反社チェッククリアのレスポンスが返ってくる' do
        expect(get_account_level['flags'].include?('ban')).to be true
      end
    end

    context 'アクセストークンが有効期限切れで失効している場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000020003' }

      it 'エラーが発生すること' do
        expect { get_account_level }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'ユーザー認証トークンが有効期限切れで失効している場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000020004' }

      it 'エラーが発生すること' do
        expect { get_account_level }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context '存在しない、あるいは無効にされた認証情報である場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000020005' }

      it 'エラーが発生すること' do
        expect { get_account_level }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'invalid_userに引っかかるユーザー' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000020005' }

      it 'リトライを指定の回数行っていること' do
        allow(Sixgram::MockUser).to receive(:find_mock).and_return(JSON.parse({ ok?: false, response: { code: '401' }, error: 'invalid_user', error_description: 'invalid_user', user_id: '09000020002' }.to_json, object_class: OpenStruct))

        expect { get_account_level }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
        expect(Sixgram::MockUser).to have_received(:find_mock).exactly(3).times
      end
    end
  end

  describe '#get_personal_data', :sales_jwt_mock do
    subject(:get_personal_data) { described_class.get_personal_data(sixgram_access_token) }

    context 'デフォルト ユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it 'NULLのデータが返ってくること' do
        personal_data = { 'birthdate' => nil, 'family_kana' => nil, 'family_name' => nil, 'given_kana' => nil, 'given_name' => nil }
        expect(get_personal_data).to have_attributes(personal_data)
      end
    end

    context 'MIXI M会員ユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010121' }

      it '生年月日・氏名・かなのデータが返ってくること' do
        personal_data = { 'birthdate' => '20210101', 'family_kana' => 'ケイリン', 'family_name' => '競輪', 'given_kana' => 'タロウ', 'given_name' => '太郎' }
        expect(get_personal_data).to have_attributes(personal_data)
      end
    end

    context 'トークンが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

      it 'エラーが発生すること' do
        expect { get_personal_data }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '生年月日が未登録のユーザー' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010021' }

      it '生年月日が空であること' do
        expect(get_personal_data['birthdate'].present?).to be false
      end
    end
  end

  describe '#get_identification_status', :sales_jwt_mock do
    subject(:get_identification_status) { described_class.get_identification_status(sixgram_access_token) }

    context 'デフォルト 本人確認状況: 未確認' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it 'not_uploadedであること' do
        expect(get_identification_status['status']).to eq('not_uploaded')
      end
    end

    context 'トークンが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

      it 'エラーが発生すること' do
        expect { get_identification_status }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '本人確認状況: 確認中' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010022' }

      it 'in_progressであること' do
        expect(get_identification_status['status']).to eq('in_progress')
      end
    end

    context '本人確認状況: 完了' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010023' }

      it 'approvedであること' do
        expect(get_identification_status['status']).to eq('approved')
      end
    end

    context '本人確認状況: 差し戻し' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010024' }

      it 'rejectedであること' do
        expect(get_identification_status['status']).to eq('rejected')
      end
    end
  end

  describe '#post_user_name', :sales_jwt_mock do
    subject(:post_user_name) { described_class.post_user_name(sixgram_access_token, 'family_name', 'given_name', 'family_kana', 'given_kana') }

    context 'デフォルト 正常系' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it '200 statusが返ってくること' do
        expect(post_user_name.response.code).to eq('200')
      end
    end

    context 'トークンが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

      it 'エラーが発生すること' do
        expect { post_user_name }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '不正なパラメーター: 入力が空' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010025' }

      it 'エラーが発生すること' do
        expect { post_user_name }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '不正なパラメーター: 入力フォーマットが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010026' }

      it 'エラーが発生すること' do
        expect { post_user_name }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end
  end

  describe '#post_birthdate', :sales_jwt_mock do
    subject(:post_birthdate) { described_class.post_birthdate(sixgram_access_token, '20200101') }

    context 'デフォルト 正常系' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it '200 statusが返ってくること' do
        expect(post_birthdate.response.code).to eq('200')
      end
    end

    context 'トークンが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

      it 'エラーが発生すること' do
        expect { post_birthdate }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '不正なパラメーター: 入力が空' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010027' }

      it 'エラーが発生すること' do
        expect { post_birthdate }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end

    context '不正なパラメーター: 入力フォーマットが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010028' }

      it 'エラーが発生すること' do
        expect { post_birthdate }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end
  end

  describe '#payment_deposit', :sales_jwt_mock do
    subject(:payment_deposit) { described_class.payment_deposit(sixgram_access_token, '20200101', 'https://example.com/', []) }

    context 'デフォルト 正常系' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it '200 statusが返ってくること' do
        expect(payment_deposit.response.code).to eq('200')
      end
    end

    context 'トークンが不正' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010004' }

      it 'エラーが発生すること' do
        expect { payment_deposit }.to raise_error(InvalidSixgramUserAuthError, 'エラーが発生しました')
      end
    end
  end

  describe '#get_migration_validate', :sales_jwt_mock do
    subject(:get_migration_validate) { described_class.get_migration_validate(sixgram_access_token) }

    context 'デフォルト ユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it 'migration_requiredがfalseで返ってくること' do
        expect(get_migration_validate['migration_required'].present?).to be false
      end
    end

    context 'migrationが必要なユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000050001' }

      it 'migration_requiredがtrueで返ってくること' do
        expect(get_migration_validate['migration_required'].present?).to be true
      end
    end

    context '自動的に解決できない競合が発生しているユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000050002' }

      it 'エラーが発生すること' do
        expect { get_migration_validate }.to raise_error(InvalidMigrationError, 'お問い合わせでの対応が必要です')
      end
    end

    context 'invalid_userに引っかかるユーザー' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000050003' }

      it 'リトライを指定の回数行っていること' do
        allow(Sixgram::MockUser).to receive(:find_mock).and_return(JSON.parse({ ok?: false, response: { code: '401' }, error: 'invalid_user', error_description: 'invalid_user', user_id: '09000050003' }.to_json, object_class: OpenStruct))

        expect { get_migration_validate }.to raise_error(InvalidSixgramUserAuthError, '6gramApiにエラーが発生しました')
        expect(Sixgram::MockUser).to have_received(:find_mock).exactly(3).times
      end
    end
  end

  describe '#post_migration_apply', :sales_jwt_mock do
    subject(:post_migration_apply) { described_class.post_migration_apply(sixgram_access_token) }

    context 'デフォルト ユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it 'okが帰ってくること' do
        expect(post_migration_apply.ok?).to be true
      end
    end

    context '移行済みユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000060001' }

      it 'エラーが発生すること' do
        expect { post_migration_apply }.to raise_error(CustomError, 'すでに移行済みです')
      end
    end

    context '自動的に解決できない競合が発生しているユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000060002' }

      it 'エラーが発生すること' do
        expect { post_migration_apply }.to raise_error(InvalidMigrationError, 'お問い合わせでの対応が必要です')
      end
    end
  end
end
