# frozen_string_literal: true

require 'rails_helper'

describe SessionProfile, :sales_jwt_mock, type: :model do
  let(:session_profile) { described_class.new(sixgram_access_token) }
  let(:profile_attributes) do
    {
      'family_name' => '競輪テスト',
      'given_name' => '太郎テスト',
      'family_name_kana' => 'ケイリンテスト',
      'given_name_kana' => 'タロウテスト',
      'birthday' => '2000-01-01T00:00:00+00:00',
      'email' => 'example@example.com'
    }
  end

  describe '#attributes=' do
    subject(:get_attributes) { described_class.new(user_auth_token).attributes }

    before do
      session_profile.attributes = profile_attributes
    end

    context 'user_auth_tokenセッションが一致している場合' do
      let(:user_auth_token) { sixgram_access_token }

      it 'SessionProfileに入れたprofileが取得できること' do
        expect(get_attributes).to eq(profile_attributes)
      end
    end

    context 'user_auth_tokenセッションが一致していない場合' do
      let(:user_auth_token) do
        payload =
          {
            sub: 'other_token',
            iat: sixgram_access_token_iat,
            exp: sixgram_access_token_exp
          }
        JWT.encode(payload, sixgram_access_token_key)
      end

      it 'SessionProfileに入れたprofileは取得できないこと' do
        expect(get_attributes).not_to eq(profile_attributes)
      end
    end
  end

  describe '#attributes' do
    subject(:get_attributes) { session_profile.attributes }

    context 'SessionProfileに入力があった場合' do
      before do
        session_profile.attributes = profile_attributes
      end

      it 'SessionProfileに入れたprofileが取得できること' do
        expect(get_attributes).to eq(profile_attributes)
      end

      context '6gramからの個人情報がある場合' do
        let(:sales_jwt_mock_user_sixgram_id) { '09000010122' } # birthdayはnil、それ以外は登録がある

        it '6gramからの個人情報で上書きされていること、6gramの情報がnilの場合は入力された情報が優先されること' do
          personal_data = ApiProvider.sixgram.get_personal_data(sixgram_access_token)
          expect_data = get_attributes

          expect(expect_data[:birthday]).to eq('2000-01-01T00:00:00+00:00')
          expect(expect_data[:family_name]).to eq(personal_data['family_name'])
          expect(expect_data[:given_name]).to eq(personal_data['given_name'])
          expect(expect_data[:family_name_kana]).to eq(personal_data['family_kana'])
          expect(expect_data[:given_name_kana]).to eq(personal_data['given_kana'])
        end
      end
    end

    context 'SessionProfileに何も入れてない場合' do
      it '空のHashが返ってくること' do
        expect(get_attributes).to eq({})
      end
    end
  end

  describe '#sixgram_identity_verified?' do
    subject(:data) { Sixgram::Service.get_personal_data(user_auth_token).to_h }

    context '個人情報取得APIを投げた場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010121' }
      let(:user_auth_token) { sixgram_access_token }
      let(:expect_attributes) do
        {
          birthdate: '20210101',
          family_kana: 'ケイリン',
          family_name: '競輪',
          given_kana: 'タロウ',
          given_name: '太郎'
        }
      end

      it '期待通りの値が返ってくること' do
        expect(data[:ok?]).to eq true
        expect(data[:birthdate]).to eq expect_attributes[:birthdate]
        expect(data[:family_kana]).to eq expect_attributes[:family_kana]
        expect(data[:family_name]).to eq expect_attributes[:family_name]
        expect(data[:given_kana]).to eq expect_attributes[:given_kana]
        expect(data[:given_name]).to eq expect_attributes[:given_name]
      end
    end
  end

  describe '#post_personal_data' do
    subject(:post_personal_data) { described_class.new(sixgram_access_token).post_personal_data }

    before do
      described_class.new(sixgram_access_token).attributes = profile_attributes
    end

    context '氏名のフォーマットに誤りがある場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010026' }

      it 'エラーが発生すること' do
        expect { post_personal_data }.to raise_error(InvalidSixgramUserAuthError)
      end
    end

    context '生年月日のフォーマットに誤りがある場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010027' }

      it 'エラーが発生すること' do
        expect { post_personal_data }.to raise_error(InvalidSixgramUserAuthError)
      end
    end
  end

  describe '#sixgram_personal_data' do
    subject(:sixgram_personal_data) { session_profile.sixgram_personal_data }

    context '6gramからの個人情報がある場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '09000010121' }

      it '6gramからの個人情報が返ってくること' do
        personal_data = ApiProvider.sixgram.get_personal_data(sixgram_access_token)
        expect_data = sixgram_personal_data

        expect(expect_data[:birthday]).to eq('20210101')
        expect(expect_data[:family_name]).to eq(personal_data['family_name'])
        expect(expect_data[:given_name]).to eq(personal_data['given_name'])
        expect(expect_data[:family_name_kana]).to eq(personal_data['family_kana'])
        expect(expect_data[:given_name_kana]).to eq(personal_data['given_kana'])
      end
    end

    context '6gramからの個人情報がない場合' do
      let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

      it '6gramからの個人情報が返って来ないこと' do
        expect_data = sixgram_personal_data

        expect(expect_data[:birthday]).to be_nil
        expect(expect_data[:family_name]).to be_nil
        expect(expect_data[:given_name]).to be_nil
        expect(expect_data[:family_name_kana]).to be_nil
        expect(expect_data[:given_name_kana]).to be_nil
      end
    end
  end

  describe '#sixgram_id' do
    subject(:sixgram_id) { session_profile.sixgram_id }

    context 'JWT期限切れの場合' do
      let(:sixgram_access_token_exp) { (sixgram_access_token_iat - 1.hour).to_i }

      it 'LoginRequiredErrorが発生すること' do
        expect { sixgram_id }.to raise_error(LoginRequiredError, 'もう一度電話番号を入力してください')
      end
    end

    context '不正なJWTだった場合' do
      let(:sixgram_access_token_key) { SecureRandom.uuid }

      it 'InvalidSixgramUserAuthErrorが発生すること' do
        expect { sixgram_id }.to raise_error(InvalidSixgramUserAuthError, 'ユーザー認証に失敗しました')
      end
    end
  end
end
