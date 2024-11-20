# frozen_string_literal: true

require 'rails_helper'

describe MixiM::Service do
  describe '#get_token(code, code_verifire)', :sales_jwt_mock do
    subject(:get_token) { described_class.get_token(code, code_verifire) }

    let(:code_verifire) { SecureRandom.uuid }

    context 'デフォルト' do
      let(:code) { '08012345678' }

      it '想定通りのレスポンスが返ってくること' do
        token = get_token
        payload, _header = JWT.decode(token.legacy_auth_token, nil, false)
        expect(payload['sub']).to eq(code)
      end
    end

    context '必要なパラメーターが不足 invalid_request' do
      let(:code) { '07000010000' }

      it 'LoginRequiredErrorが発生すること' do
        expect { get_token }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'codeが不正 invalid_grant' do
      let(:code) { '07000010001' }

      it 'LoginRequiredErrorが発生すること' do
        expect { get_token }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'クライアント認証に失敗 invalid_client' do
      let(:code) { '07000010002' }

      it 'LoginRequiredErrorが発生すること' do
        expect { get_token }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context '予期せぬエラー internal_server_error' do
      let(:code) { '07000019999' }

      it 'FatalMixiMApiErrorが発生すること' do
        expect { get_token }.to raise_error(FatalMixiMApiError, 'エラーが発生しました')
      end
    end
  end

  describe '#get_user_info(accsess_token)', :sales_jwt_mock do
    subject(:get_user_info) { described_class.get_user_info(sixgram_access_token) }

    context 'デフォルト ユーザーの場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it '情報が返ってくること' do
        user_info = { 'birthday' => '2000-01-01T00:00:00+00:00', 'email' => 'example@example.com', 'family_name_kana' => 'ケイリンテスト', 'family_name' => '競輪テスト', 'given_name_kana' => 'タロウテスト', 'given_name' => '太郎テスト', 'phone_number' => '08012345678' }
        expect(get_user_info).to have_attributes(user_info)
      end
    end

    context 'データがない場合(誕生日)' do
      let(:sales_jwt_mock_user_sixgram_id) { '07000020000' }

      it '生年月日・氏名・かなのデータが返ってくること' do
        user_info = { 'birthday' => nil, 'email' => 'example@example.com', 'family_name_kana' => 'ケイリンテスト', 'family_name' => '競輪テスト', 'given_name_kana' => 'タロウテスト', 'given_name' => '太郎テスト', 'phone_number' => '07000020000' }
        expect(get_user_info).to have_attributes(user_info)
      end
    end

    context 'その他のパラメータエラー' do
      let(:sales_jwt_mock_user_sixgram_id) { '07000020001' }

      it 'エラーが発生すること' do
        expect { get_user_info }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'code が不正、使用済みなど' do
      let(:sales_jwt_mock_user_sixgram_id) { '07000020002' }

      it 'エラーが発生すること' do
        expect { get_user_info }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'クライアント認証に失敗' do
      let(:sales_jwt_mock_user_sixgram_id) { '07000020003' }

      it 'エラーが発生すること' do
        expect { get_user_info }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context '予期せぬエラー' do
      let(:sales_jwt_mock_user_sixgram_id) { '07000029999' }

      it 'InvalidMixiMUserAuthErrorが発生すること' do
        expect { get_user_info }.to raise_error(InvalidMixiMUserAuthError, 'エラーが発生しました')
      end
    end
  end

  describe '#reget_token(refresh_token)', :sales_jwt_mock do
    subject(:reget_token) { described_class.reget_token(refresh_token) }

    context 'デフォルト' do
      let(:refresh_token) { '08012345678' }

      it '想定通りのレスポンスが返ってくること' do
        token = reget_token
        payload, _header = JWT.decode(token.refresh_token, nil, false)
        expect(payload['sub']).to eq(refresh_token)
      end
    end

    context '必要なパラメーターが不足 invalid_request' do
      let(:refresh_token) { '07000030000' }

      it 'LoginRequiredErrorが発生すること' do
        expect { reget_token }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'codeが不正 invalid_grant' do
      let(:refresh_token) { '07000030001' }

      it 'LoginRequiredErrorが発生すること' do
        expect { reget_token }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context 'クライアント認証に失敗 invalid_client' do
      let(:refresh_token) { '07000030002' }

      it 'LoginRequiredErrorが発生すること' do
        expect { reget_token }.to raise_error(LoginRequiredError, 'もう一度ログインしてください')
      end
    end

    context '予期せぬエラー internal_server_error' do
      let(:refresh_token) { '07000039999' }

      it 'FatalMixiMApiErrorが発生すること' do
        expect { reget_token }.to raise_error(FatalMixiMApiError, 'エラーが発生しました')
      end
    end
  end
end
