# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'UsersController', type: :request do
  describe 'POST sales/users/send_sms_auth_code' do
    subject(:post_send_sms_auth_code) { post sales_users_send_sms_auth_code_url(params) }

    let(:params) { { phoneNumber: phone_number, isRegister: is_register } }
    let(:phone_number) { '08012345678' }

    context '正常な処理の場合' do
      let(:is_register) { false }

      it 'SMS検証セッションが作成されていること' do
        post_send_sms_auth_code
        expect(session[:sms_verify_token].present?).to be true
      end
    end

    context '登録済みの電話番号だった場合' do
      let(:is_register) { true }

      it 'エラーを返すこと' do
        user = create(:user, :with_profile, sixgram_id: phone_number)
        create(:profile, user: user, phone_number: phone_number)
        post_send_sms_auth_code
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('この電話番号はすでに登録済です。<br />ログイン画面より再度ログインしてください。')
      end
    end
  end

  describe 'POST sales/users/verify_sms_auth_code' do
    subject(:verify_sms_auth_code) { post sales_users_verify_sms_auth_code_url(params) }

    let(:params) { { sms_auth_code: '0000' } }

    context 'SMS認証コード送信済みの時' do
      before do
        post sales_users_send_sms_auth_code_url(phone_number: phone_number)
      end

      let(:phone_number) { '08012345678' }

      context 'ユーザー登録済みの場合' do
        let(:user) { create(:user, :with_profile, sixgram_id: phone_number) }

        it 'ユーザー登録済みを示すレスポンスが返ること' do
          user_id = user.id
          verify_sms_auth_code
          json = JSON.parse(response.body)
          expect(json['registered']).to be true
          expect(json['currentUser']['id']).to eq(user_id)
        end

        it 'SMS検証セッションが削除され、ユーザーセッションが作成されていること' do
          verify_sms_auth_code
          expect(session[:sms_verify_token].present?).to be false
          expect(session[:user_auth_token].present?).to be true
        end
      end

      context 'ユーザー未登録の場合' do
        it 'ユーザー未登録を示すレスポンスが返ること' do
          verify_sms_auth_code
          json = JSON.parse(response.body)
          expect(json['registered']).to be false
        end

        it 'SMS検証セッションが削除され、ユーザーセッションが作成されていること' do
          verify_sms_auth_code
          expect(session[:sms_verify_token].present?).to be false
          expect(session[:user_auth_token].present?).to be true
        end
      end

      # TODO: NGユーザーチェックスキップ
      # context 'NGユーザーの場合' do
      #   let(:phone_number) { '09000010002' }
      #   let(:user) { create(:user, :with_profile, sixgram_id: phone_number) }

      #   it '403エラーが発生すること' do
      #     verify_sms_auth_code
      #     expect(response).to have_http_status(:forbidden)
      #     body = JSON.parse(response.body)
      #     expect(body['code']).to eq('ng_user_error')
      #   end

      #   it 'ユーザーセッションが作成されていないこと' do
      #     verify_sms_auth_code
      #     expect(session[:user_auth_token].present?).to be false
      #   end
      # end

      # TODO: NGユーザーチェックスキップ
      context 'NGユーザーの場合' do
        let(:phone_number) { '09000010002' }
        let(:user) { create(:user, :with_profile, sixgram_id: phone_number) }

        it 'ユーザー登録済みを示すレスポンスが返ること' do
          user_id = user.id
          verify_sms_auth_code
          json = JSON.parse(response.body)
          expect(json['registered']).to be true
          expect(json['currentUser']['id']).to eq(user_id)
        end

        it 'SMS検証セッションが削除され、ユーザーセッションが作成されていること' do
          verify_sms_auth_code
          expect(session[:sms_verify_token].present?).to be false
          expect(session[:user_auth_token].present?).to be true
        end
      end
    end

    context 'SMS認証コードが未送信の場合' do
      it '電話番号再入力のエラーが発生すること' do
        verify_sms_auth_code
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('再度電話番号を入力してください')
      end
    end
  end

  describe 'GET sales/users/session_profile' do
    subject(:get_session_profile) { get sales_users_session_profile_url }

    let(:profile_attributes) do
      {
        'familyName' => '競輪テスト',
        'givenName' => '太郎テスト',
        'familyNameKana' => 'ケイリンテスト',
        'givenNameKana' => 'タロウテスト',
        'birthday' => '2000-01-01T00:00:00+00:00',
        'email' => 'example@example.com',
        'mailmagazine' => 'true'
      }
    end

    context '事前にSMS検証済み(ユーザーアクセストークン取得済み)' do
      before do
        allow(LoginRequiredUuid).to receive(:generate_uuid).and_return(random_uuid)
        get sales_users_url
        get sales_users_mixi_m_callback_url(code: code, state: random_uuid)
      end

      let(:code) { '08012345678' }
      let(:random_uuid) { '123' }

      context 'セッションに入力データが保存されていた場合' do
        before do
          put sales_users_confirm_url, params: { profiles: profile_attributes }
        end

        it 'セッションに保存された値が返ってくること' do
          get_session_profile
          expect(JSON.parse(response.body)['profiles']).to eq(profile_attributes)
        end
      end

      context 'セッションに入力データが保存されていない場合' do
        it '何も値が返ってこないこと' do
          get_session_profile
          expect(JSON.parse(response.body)['profiles']).to be nil
        end
      end

      context '個人情報APIの結果MIXI M会員と判定した場合' do
        before do
          put sales_users_confirm_url, params: { profiles: profile_attributes }
        end

        let(:code) { '09000010121' }

        let(:profile_attributes) do
          {
            'familyName' => '競輪テスト',
            'givenName' => '太郎テスト',
            'familyNameKana' => 'ケイリンテスト',
            'givenNameKana' => 'タロウテスト',
            'birthday' => '2000-01-01T00:00:00+00:00',
            'mailmagazine' => 'true'
          }
        end

        it 'sixgram, mixi_m API からのデータが反映されていること' do
          get_session_profile
          sixgram_data = ApiProvider.sixgram.get_personal_data(session[:user_auth_token])
          mixi_m_data = ApiProvider.mixi_m.get_user_info(session[:user_auth_token])
          data = JSON.parse(response.body)
          expect(data['identityVerified']).to be true
          expect(data['profiles']['birthday']).to eq(sixgram_data['birthdate'])
          expect(data['profiles']['familyName']).to eq(sixgram_data['family_name'])
          expect(data['profiles']['email']).to eq(mixi_m_data['email'])
        end
      end

      context 'すでにアカウント登録済みの場合' do
        before do
          session_profile = SessionProfile.new(session[:user_auth_token])
          User.create!(sixgram_id: session_profile.sixgram_id)
        end

        it 'エラーが返ってくること' do
          get_session_profile
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('既にアカウント登録済みです')
        end
      end
    end

    context 'SMS検証を飛ばしてユーザー登録へ進んだ場合' do
      it '再ログイン要求エラーが返ってくること' do
        get_session_profile
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:unauthorized)
        expect(body['detail']).to eq('もう一度MIXI Mでログインしてください')
      end
    end
  end

  describe 'DELETE sales/users/logout' do
    subject(:logout) { delete sales_users_logout_url }

    let(:profile_attributes) do
      {
        'familyName' => '競輪テスト',
        'givenName' => '太郎テスト',
        'familyNameKana' => 'ケイリンテスト',
        'givenNameKana' => 'タロウテスト',
        'birthday' => '2000-01-01T00:00:00+00:00',
        'email' => 'example@example.com',
        'mailmagazine' => 'true'
      }
    end

    context '事前にSMS検証済み(ユーザーアクセストークン取得済み)' do
      before do
        allow(LoginRequiredUuid).to receive(:generate_uuid).and_return(random_uuid)
        get sales_users_url
        get sales_users_mixi_m_callback_url(code: code, state: random_uuid)
      end

      let(:code) { '08012345678' }
      let(:random_uuid) { '123' }

      context 'セッションに入力データが保存されていない場合' do
        before do
          put sales_users_confirm_url, params: { profiles: profile_attributes }
        end

        it '何も値が返ってこないこと' do
          get sales_users_session_profile_url
          expect(JSON.parse(response.body)['profiles']).to eq(profile_attributes)
          logout
          get sales_users_session_profile_url
          expect(JSON.parse(response.body)['code']).to eq('login_required')
          expect(session[:user_auth_token].present?).to be false
        end
      end
    end
  end

  describe 'PUT sales/users/confirm' do
    subject(:put_profile_confirm) { put sales_users_confirm_url, params: { profiles: profile_attributes } }

    let(:profile_attributes) do
      {
        'familyName' => '競輪',
        'givenName' => '太郎',
        'familyNameKana' => 'ケイリン',
        'givenNameKana' => 'タロウ',
        'birthday' => '2021-01-01T00:00:00+00:00',
        'email' => 'example@example.com',
        'zip_code' => '0123456',
        'prefecture' => '東京都',
        'city' => '足立区',
        'address_line' => '足立1-1-1',
        'mailmagazine' => 'true',
        'agreement' => true
      }
    end

    context '事前にSMS検証済み(ユーザーアクセストークン取得済み)' do
      before do
        allow(LoginRequiredUuid).to receive(:generate_uuid).and_return(random_uuid)
        get sales_users_url
        get sales_users_mixi_m_callback_url(code: code, state: random_uuid)
        post sales_users_verify_sms_auth_code_url('0000')
      end

      let(:code) { '08012345678' }
      let(:random_uuid) { '123' }

      context '正常なデータが入力されていた場合' do
        it '200が返ってくること' do
          put_profile_confirm
          expect(response).to have_http_status(:ok)
        end
      end

      context '不正なデータが入力されていた場合' do
        let(:profile_attributes) do
          {
            'familyName' => '競輪',
            'givenName' => '太郎',
            'familyNameKana' => 'ケイリン',
            'givenNameKana' => 'タロウ',
            'birthday' => '2021-01-01T00:00:00+00:00',
            'email' => 'example@example.com',
            'zip_code' => '1',
            'prefecture' => '東京都',
            'city' => '足立区',
            'address_line' => '足立1-1-1',
            'mailmagazine' => 'true',
            'agreement' => true
          }
        end

        it '400エラーが返ってくること' do
          put_profile_confirm
          expect(response).to have_http_status(:bad_request)
        end
      end

      context '利用規約に同意していない場合' do
        let(:profile_attributes) do
          {
            'familyName' => '競輪',
            'givenName' => '太郎',
            'familyNameKana' => 'ケイリン',
            'givenNameKana' => 'タロウ',
            'birthday' => '2021-01-01T00:00:00+00:00',
            'email' => 'example@example.com',
            'zip_code' => '0123456',
            'prefecture' => '東京都',
            'city' => '足立区',
            'address_line' => '足立1-1-1',
            'mailmagazine' => 'true'
          }
        end

        it '400エラーが返ってくること' do
          put_profile_confirm
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context 'SMS検証を飛ばしてユーザー登録へ進んだ場合' do
      it '再ログイン要求エラーが返ってくること' do
        put_profile_confirm
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST sales/users' do
    subject(:post_user) { post sales_users_url, params: { profiles: profile_attributes } }

    let(:profile_attributes) do
      {
        'familyName' => '競輪',
        'givenName' => '太郎',
        'familyNameKana' => 'ケイリン',
        'givenNameKana' => 'タロウ',
        'birthday' => '2021-01-01T00:00:00+00:00',
        'email' => 'example@example.com',
        'zip_code' => '0123456',
        'prefecture' => '東京都',
        'city' => '足立区',
        'address_line' => '足立1-1-1',
        'mailmagazine' => 'true'
      }
    end

    context '事前にSMS検証済み(ユーザーアクセストークン取得済み)' do
      before do
        allow(LoginRequiredUuid).to receive(:generate_uuid).and_return(random_uuid)
        get sales_users_url
        get sales_users_mixi_m_callback_url(code: code, state: random_uuid)
        create(:coupon, :available_coupon)
        create(:coupon, :available_coupon)
      end

      let(:code) { '08012345678' }
      let(:random_uuid) { '123' }

      context '正常なデータが入力されていた場合' do
        before do
          put sales_users_confirm_url, params: { profiles: profile_attributes }
        end

        it 'UserとProfileが作成されること' do
          expect { post_user }.to change(User, :count).from(0).to(1).and change(Profile, :count).from(0).to(1)
          expect(response).to have_http_status(:ok)
          user = User.last
          profile = Profile.last
          expect(user.qr_user_id).to be_truthy
          expect(profile.phone_number).to eq(session[:phone_number])
          expect(profile.auth_code).to eq(session[:user_auth_token])
          expect(profile.ng_user_check).to be_truthy
        end

        it '認証メールが送信されること' do
          expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { post_user } }.to change { ActionMailer::Base.deliveries.count }.by(1)
          expect(ActionMailer::Base.deliveries.map(&:to)).to include ['example@example.com']
          expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】仮登録が完了しました'
        end

        it '6gramへ氏名と生年月日のデータ共有がpostされること' do
          allow(Sixgram::Service).to receive(:post_user_name)
          allow(Sixgram::Service).to receive(:post_birthdate)

          post_user
          expect(Sixgram::Service).to have_received(:post_user_name)
          expect(Sixgram::Service).to have_received(:post_user_name)
        end

        it 'user_couponが作成されること' do
          expect { post_user }.to change(User, :count).from(0).to(1).and change(UserCoupon, :count).from(0).to(2)
          user = User.first
          expect(user.user_coupons.size).to eq(2)
          expect(user.user_coupons.first.user_id).to eq(user.id)
          expect(user.user_coupons.last.user_id).to eq(user.id)
        end

        it '全員対象のクーポンであるなら、配布予定日が過ぎていないくてもuser_couponが作成されること' do
          coupon = create(:coupon, :available_coupon)
          coupon.update(scheduled_distributed_at: Time.zone.now + 2.hours) # 配布予定日を未来に設定

          expect { post_user }.to change(UserCoupon, :count).from(0).to(3)
          user = User.first
          expect(user.user_coupons.size).to eq(3)
          expect(user.user_coupons.find_by(coupon_id: coupon.id)).to be_present
        end
      end

      context '不正なデータが入力されていた場合' do
        before do
          put sales_users_confirm_url, params: { profiles: profile_attributes }
        end

        let(:profile_attributes) do
          {
            'familyName' => '競輪',
            'givenName' => '太郎',
            'familyNameKana' => 'ケイリン',
            'givenNameKana' => 'タロウ',
            'birthday' => '2021-01-01T00:00:00+00:00',
            'email' => 'example@example.com',
            'zip_code' => '1',
            'prefecture' => '東京都',
            'city' => '足立区',
            'address_line' => '足立1-1-1',
            'mailmagazine' => 'true'
          }
        end

        it 'UserとProfileが作成されないこと' do
          expect { post_user }.not_to change(User, :count)
          expect { post_user }.not_to change(Profile, :count)
          expect(response).to have_http_status(:bad_request)
        end

        it '認証メールが送信されないこと' do
          expect { post_user }.not_to change { ActionMailer::Base.deliveries.count }
        end
      end

      context '個人情報APIの結果6gramに情報があった場合' do
        before do
          put sales_users_confirm_url, params: { profiles: profile_attributes }
        end

        let(:code) { '09000010121' }

        it 'sixgram API からのデータが反映されていること' do
          post_user
          sixgram_data = ApiProvider.sixgram.get_personal_data(session[:user_auth_token])
          expect_attr = {
            birthday: Date.parse(sixgram_data['birthdate']),
            family_name: sixgram_data['family_name'],
            given_name: sixgram_data['given_name'],
            family_name_kana: sixgram_data['family_kana'],
            given_name_kana: sixgram_data['given_kana']
          }

          expect(Profile.last).to have_attributes(expect_attr)
        end

        it '6gramへ氏名と生年月日のデータ共有がpostされないこと' do
          allow(Sixgram::Service).to receive(:post_user_name)
          allow(Sixgram::Service).to receive(:post_birthdate)

          post_user
          expect(Sixgram::Service).not_to have_received(:post_user_name)
          expect(Sixgram::Service).not_to have_received(:post_user_name)
        end

        context '6gram情報に不足があった場合' do
          let(:code) { '09000010122' }

          it 'sixgram API からのデータが反映されていること、情報が不足（birthday）している場合は入力値が入っていること' do
            post_user
            sixgram_data = ApiProvider.sixgram.get_personal_data(session[:user_auth_token])
            expect_attr = {
              birthday: Date.parse(profile_attributes['birthday']),
              family_name: sixgram_data['family_name'],
              given_name: sixgram_data['given_name'],
              family_name_kana: sixgram_data['family_kana'],
              given_name_kana: sixgram_data['given_kana']
            }

            expect(Profile.last).to have_attributes(expect_attr)
          end

          it '6gramへ氏名と生年月日のデータ共有がpostされること' do
            allow(Sixgram::Service).to receive(:post_user_name)
            allow(Sixgram::Service).to receive(:post_birthdate)

            post_user
            expect(Sixgram::Service).to have_received(:post_user_name)
            expect(Sixgram::Service).to have_received(:post_user_name)
          end
        end
      end
    end

    context 'SMS検証を飛ばしてユーザー登録へ進んだ場合' do
      it '再ログイン要求エラーが返ってくること' do
        post_user
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET sales/users', :sales_logged_in do
    subject(:get_user) { get sales_users_url }

    it 'ユーザーが取得できている事' do
      get_user
      json_body = JSON.parse(response.body)
      expect(json_body['currentUser']['id']).to eq(sales_logged_in_user.id)
    end

    context 'ログイン時にマイグレーションが必要な場合' do
      let(:sales_logged_in_user_code) { '09000050004' }

      it 'エラーが上がって、想定通りの返り値が返ること' do
        sales_logged_in_user_code
        get_user
        json = JSON.parse(response.body)
        expect(response.status).to eq(401)
        expect(json['code']).to eq('need_migration_error')
        expect(json['detail']).to eq('name,birthdate,payee_bank,id_proofing_status')
      end
    end

    it 'ログイン時にsession[:code_verifire],session[:code_state],session[:code_nonce]がnilになっていること' do
      get_user
      expect(session[:code_verifire]).to be_nil
      expect(session[:code_state]).to be_nil
      expect(session[:code_nonce]).to be_nil
    end
  end

  describe 'GET sales/users:無効なsessionでログインしている場合', :sales_logged_in do
    subject(:get_user) { get sales_users_url }

    before do
      allow(Sixgram::Service).to receive(:get_migration_validate).and_raise(InvalidSixgramUserAuthError)
    end

    it 'sessionがリセットされていること' do
      get_user
      expect(session[:user_auth_token].blank?).to be true
      expect(session[:access_token].blank?).to be true
      expect(session[:refresh_token].blank?).to be true
    end

    it 'sessionにcode_verifire,code_state,code_nonceが入っていること' do
      get_user
      expect(session[:code_verifire]).to be_present
      expect(session[:code_state]).to be_present
      expect(session[:code_nonce]).to be_present
    end

    it 'codeChallenge,state,nonceがレスポンスに入っている事' do
      get_user
      json_body = JSON.parse(response.body)
      expect(json_body['currentUser']['codeChallenge']).to be_present
      expect(json_body['currentUser']['state']).to be_present
      expect(json_body['currentUser']['nonce']).to be_present
    end
  end

  describe 'GET sales/users:ログインしていない場合' do
    subject(:get_user) { get sales_users_url }

    it 'codeChallenge,state,nonceがレスポンスに入っている事' do
      get_user
      json_body = JSON.parse(response.body)
      expect(json_body['currentUser']['codeChallenge']).to be_present
      expect(json_body['currentUser']['state']).to be_present
      expect(json_body['currentUser']['nonce']).to be_present
    end

    it 'sessionにcode_verifire,code_state,code_nonceが入っていること' do
      get_user
      expect(session[:code_verifire]).to be_present
      expect(session[:code_state]).to be_present
      expect(session[:code_nonce]).to be_present
    end
  end

  describe 'GET sales/users/profile', :sales_logged_in do
    subject(:get_user) { get sales_users_profile_url }

    it 'ユーザーが取得できている事' do
      get_user
      json_body = JSON.parse(response.body)
      expect(json_body['fullName']).to eq(sales_logged_in_user.profile.full_name)
    end

    context '6gramに個人情報が登録されている場合' do
      let(:sales_logged_in_user_code) { '09000010122' }

      it '氏名・カナ・誕生日は6gramの個人情報が優先して出力される事' do
        get_user
        json_body = JSON.parse(response.body)
        expect(json_body['familyName']).to eq('競輪')
        expect(json_body['birthday']).to be_nil
        expect(json_body['fullName']).to eq(sales_logged_in_user.profile.full_name)
      end
    end
  end

  describe 'GET sales/users/email', :sales_logged_in do
    subject(:get_user) { get sales_users_email_url }

    it 'ユーザーが取得できている事' do
      get_user
      json_body = JSON.parse(response.body)
      expect(json_body['email']).to eq(sales_logged_in_user.profile.email)
    end
  end

  describe 'UPDATE sales/users', :sales_logged_in do
    subject(:update_user) do
      perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
        put sales_users_url, params: { profiles: update_profile_attributes }
      end
    end

    context '6gramで変更不可ステータスでemailに変更がある場合' do
      let(:sixgram_id) { '09000010023' }
      let(:update_profile_attributes) do
        {
          'familyName' => '競輪',
          'givenName' => '太郎',
          'familyNameKana' => 'ケイリン',
          'givenNameKana' => 'タロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => 'example2@example.com',
          'email_confirmation' => 'example2@example.com',
          'zip_code' => '1234567',
          'prefecture' => 'テスト1',
          'city' => 'テスト2',
          'address_line' => 'テスト3',
          'mailmagazine' => 'false'
        }
      end

      let(:sales_logged_in_user) { create(:user, :with_profile, sixgram_id: sales_logged_in_user_code, email_verified: true) }

      it 'emailが更新されて、認証フラグがfalseであること' do
        expect { update_user }.to change { sales_logged_in_user.reload.email_verified }.from(true).to(false).and \
          change { sales_logged_in_user.profile.reload.email }.to('example2@example.com').and \
            change { sales_logged_in_user.reload.email_auth_code }.and \
              change { sales_logged_in_user.reload.email_auth_expired_at }.and \
                change { sales_logged_in_user.profile.reload.zip_code }.to('1234567').and \
                  change { sales_logged_in_user.profile.reload.prefecture }.to('テスト1').and \
                    change { sales_logged_in_user.profile.reload.city }.to('テスト2').and \
                      change { sales_logged_in_user.profile.reload.address_line }.to('テスト3').and \
                        change { sales_logged_in_user.profile.reload.mailmagazine }.from(true).to(false)
        expect { update_user }.not_to change {
                                        [sales_logged_in_user.profile.reload.family_name,
                                         sales_logged_in_user.profile.reload.given_name,
                                         sales_logged_in_user.profile.reload.family_name_kana,
                                         sales_logged_in_user.profile.reload.given_name_kana,
                                         sales_logged_in_user.profile.reload.birthday]
                                      }

        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】会員情報の変更が完了しました'
      end
    end

    context '6gramで変更不可ステータスでemailに変更がない場合' do
      let(:sixgram_id) { '09000010023' }
      let(:update_profile_attributes) do
        {
          'familyName' => '競輪',
          'givenName' => '太郎',
          'familyNameKana' => 'ケイリン',
          'givenNameKana' => 'タロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => sales_logged_in_user.profile.email,
          'email_confirmation' => sales_logged_in_user.profile.email,
          'mailmagazine' => 'false'
        }
      end

      it 'emailが更新されないこと' do
        expect { update_user }.to change { sales_logged_in_user.profile.reload.mailmagazine }.from(true).to(false)
        expect { update_user }.not_to change {
                                        [sales_logged_in_user.profile.reload.email,
                                         sales_logged_in_user.reload.email_auth_code,
                                         sales_logged_in_user.reload.email_auth_expired_at,
                                         sales_logged_in_user.profile.reload.family_name,
                                         sales_logged_in_user.profile.reload.given_name,
                                         sales_logged_in_user.profile.reload.family_name_kana,
                                         sales_logged_in_user.profile.reload.given_name_kana,
                                         sales_logged_in_user.profile.reload.birthday]
                                      }
      end
    end

    context '6gramで変更可能ステータスでemailに変更がある場合' do
      let(:update_profile_attributes) do
        {
          'familyName' => '競輪',
          'givenName' => '太郎',
          'familyNameKana' => 'ケイリン',
          'givenNameKana' => 'タロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => 'example2@example.com',
          'email_confirmation' => 'example2@example.com',
          'zip_code' => '1234567',
          'prefecture' => 'テスト1',
          'city' => 'テスト2',
          'address_line' => 'テスト3',
          'mailmagazine' => 'false'
        }
      end

      let(:sales_logged_in_user) { create(:user, :with_profile, sixgram_id: sales_logged_in_user_code, email_verified: true) }

      it 'emailが更新されて、認証フラグがfalseであること' do
        old_birthday = sales_logged_in_user.profile.birthday.strftime('%Y%m%d')
        expect { update_user }.to change { sales_logged_in_user.reload.email_verified }.from(true).to(false).and \
          change { sales_logged_in_user.profile.reload.email }.to('example2@example.com').and \
            change { sales_logged_in_user.reload.email_auth_code }.and \
              change { sales_logged_in_user.reload.email_auth_expired_at }.and \
                change { sales_logged_in_user.profile.reload.zip_code }.to('1234567').and \
                  change { sales_logged_in_user.profile.reload.prefecture }.to('テスト1').and \
                    change { sales_logged_in_user.profile.reload.city }.to('テスト2').and \
                      change { sales_logged_in_user.profile.reload.address_line }.to('テスト3').and \
                        change { sales_logged_in_user.profile.reload.mailmagazine }.from(true).to(false).and \
                          change { sales_logged_in_user.profile.reload.family_name }.from('山田').to('競輪').and \
                            change { sales_logged_in_user.profile.reload.given_name }.from('花子').to('太郎').and \
                              change { sales_logged_in_user.profile.reload.family_name_kana }.from('ヤマダ').to('ケイリン').and \
                                change { sales_logged_in_user.profile.reload.given_name_kana }.from('ハナコ').to('タロウ').and \
                                  change { sales_logged_in_user.profile.reload.birthday.strftime('%Y%m%d') }.from(old_birthday).to('20210101')

        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】会員情報の変更が完了しました'
      end
    end

    context '6gramで変更可能ステータスでemailに変更がない場合' do
      let(:update_profile_attributes) do
        {
          'familyName' => '競輪',
          'givenName' => '太郎',
          'familyNameKana' => 'ケイリン',
          'givenNameKana' => 'タロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => sales_logged_in_user.profile.email,
          'email_confirmation' => sales_logged_in_user.profile.email,
          'mailmagazine' => 'false'
        }
      end

      it 'emailが更新されないこと' do
        old_birthday = sales_logged_in_user.profile.birthday.strftime('%Y%m%d')
        expect { update_user }.to change { sales_logged_in_user.profile.reload.mailmagazine }.from(true).to(false).and \
          change { sales_logged_in_user.profile.reload.family_name }.from('山田').to('競輪').and \
            change { sales_logged_in_user.profile.reload.given_name }.from('花子').to('太郎').and \
              change { sales_logged_in_user.profile.reload.family_name_kana }.from('ヤマダ').to('ケイリン').and \
                change { sales_logged_in_user.profile.reload.given_name_kana }.from('ハナコ').to('タロウ').and \
                  change { sales_logged_in_user.profile.reload.birthday.strftime('%Y%m%d') }.from(old_birthday).to('20210101')
        expect { update_user }.not_to change {
                                        [sales_logged_in_user.profile.reload.email,
                                         sales_logged_in_user.reload.email_auth_code,
                                         sales_logged_in_user.reload.email_auth_expired_at]
                                      }
      end
    end

    context '6gramに個人情報がありemailに変更がある場合' do
      let(:sales_logged_in_user_code) { '09000010122' }
      let(:update_profile_attributes) do
        {
          'familyName' => '田中',
          'givenName' => '二郎',
          'familyNameKana' => 'タナカ',
          'givenNameKana' => 'ジロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => 'example2@example.com',
          'email_confirmation' => 'example2@example.com',
          'zip_code' => '1234567',
          'prefecture' => 'テスト1',
          'city' => 'テスト2',
          'address_line' => 'テスト3',
          'mailmagazine' => 'false'
        }
      end

      let(:sales_logged_in_user) { create(:user, :with_profile, sixgram_id: sales_logged_in_user_code, email_verified: true) }

      it '氏名・カナ以外は更新されて、認証フラグがfalseであること' do
        old_birthday = sales_logged_in_user.profile.birthday.strftime('%Y%m%d')
        expect { update_user }.to change { sales_logged_in_user.reload.email_verified }.from(true).to(false).and \
          change { sales_logged_in_user.profile.reload.email }.to('example2@example.com').and \
            change { sales_logged_in_user.reload.email_auth_code }.and \
              change { sales_logged_in_user.reload.email_auth_expired_at }.and \
                change { sales_logged_in_user.profile.reload.zip_code }.to('1234567').and \
                  change { sales_logged_in_user.profile.reload.prefecture }.to('テスト1').and \
                    change { sales_logged_in_user.profile.reload.city }.to('テスト2').and \
                      change { sales_logged_in_user.profile.reload.address_line }.to('テスト3').and \
                        change { sales_logged_in_user.profile.reload.mailmagazine }.from(true).to(false).and \
                          change { sales_logged_in_user.profile.reload.family_name }.from('山田').to('競輪').and \
                            change { sales_logged_in_user.profile.reload.given_name }.from('花子').to('太郎').and \
                              change { sales_logged_in_user.profile.reload.family_name_kana }.from('ヤマダ').to('ケイリン').and \
                                change { sales_logged_in_user.profile.reload.given_name_kana }.from('ハナコ').to('タロウ').and \
                                  change { sales_logged_in_user.profile.reload.birthday.strftime('%Y%m%d') }.from(old_birthday).to('20210101')

        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】会員情報の変更が完了しました'
      end

      it '6gramに情報が送信されていること' do
        allow(Sixgram::Service).to receive(:post_user_name)
        allow(Sixgram::Service).to receive(:post_birthdate)

        update_user
        expect(Sixgram::Service).to have_received(:post_user_name)
        expect(Sixgram::Service).to have_received(:post_user_name)
      end
    end

    context '6gramに個人情報がありemailに変更がない場合' do
      let(:sales_logged_in_user_code) { '09000010122' }
      let(:update_profile_attributes) do
        {
          'familyName' => '田中',
          'givenName' => '二郎',
          'familyNameKana' => 'タナカ',
          'givenNameKana' => 'ジロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => sales_logged_in_user.profile.email,
          'email_confirmation' => sales_logged_in_user.profile.email,
          'mailmagazine' => 'false'
        }
      end

      it '氏名・カナ以外は更新されて、emailが更新されないこと' do
        old_birthday = sales_logged_in_user.profile.birthday.strftime('%Y%m%d')
        expect { update_user }.to change { sales_logged_in_user.profile.reload.mailmagazine }.from(true).to(false).and \
          change { sales_logged_in_user.profile.reload.family_name }.from('山田').to('競輪').and \
            change { sales_logged_in_user.profile.reload.given_name }.from('花子').to('太郎').and \
              change { sales_logged_in_user.profile.reload.family_name_kana }.from('ヤマダ').to('ケイリン').and \
                change { sales_logged_in_user.profile.reload.given_name_kana }.from('ハナコ').to('タロウ').and \
                  change { sales_logged_in_user.profile.reload.birthday.strftime('%Y%m%d') }.from(old_birthday).to('20210101')
        expect { update_user }.not_to change {
                                        [sales_logged_in_user.profile.reload.email,
                                         sales_logged_in_user.reload.email_auth_code,
                                         sales_logged_in_user.reload.email_auth_expired_at]
                                      }
      end

      it '6gramに情報が送信されていること' do
        allow(Sixgram::Service).to receive(:post_user_name)
        allow(Sixgram::Service).to receive(:post_birthdate)

        update_user
        expect(Sixgram::Service).to have_received(:post_user_name)
        expect(Sixgram::Service).to have_received(:post_user_name)
      end
    end

    context '6gramに個人情報があり氏名・カナ・誕生日がある場合' do
      let(:sales_logged_in_user_code) { '09000010121' }
      let(:update_profile_attributes) do
        {
          'familyName' => '田中',
          'givenName' => '二郎',
          'familyNameKana' => 'タナカ',
          'givenNameKana' => 'ジロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => 'example2@example.com',
          'email_confirmation' => 'example2@example.com',
          'zip_code' => '1234567',
          'prefecture' => 'テスト1',
          'city' => 'テスト2',
          'address_line' => 'テスト3',
          'mailmagazine' => 'false'
        }
      end

      let(:sales_logged_in_user) { create(:user, :with_profile, sixgram_id: sales_logged_in_user_code, email_verified: true) }

      it '6gramに情報が送信されていないこと' do
        allow(Sixgram::Service).to receive(:post_user_name)
        allow(Sixgram::Service).to receive(:post_birthdate)

        update_user
        expect(Sixgram::Service).not_to have_received(:post_user_name)
        expect(Sixgram::Service).not_to have_received(:post_user_name)
      end
    end

    context 'emailに変更がある場合' do
      let(:update_profile_attributes) do
        {
          'familyName' => '競輪',
          'givenName' => '太郎',
          'familyNameKana' => 'ケイリン',
          'givenNameKana' => 'タロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => email,
          'email_confirmation' => email_confirmation,
          'zip_code' => '1234567',
          'prefecture' => 'テスト1',
          'city' => 'テスト2',
          'address_line' => 'テスト3',
          'mailmagazine' => 'false'
        }
      end
      let(:email) { 'example2@example.com' }

      context 'email_confirmationがemailと同じ場合' do
        let(:email_confirmation) { email }

        it 'emailが更新されて、ステータス200が返ってくること' do
          expect { update_user }.to change { sales_logged_in_user.profile.reload.email }.to('example2@example.com')
          expect(response).to have_http_status(:ok)
        end
      end

      context 'email_confirmationがemailと異なる場合' do
        let(:email_confirmation) { 'email' }

        it 'emailが更新されずに、エラーが返ってくること' do
          expect { update_user }.not_to change { sales_logged_in_user.profile.reload.email }
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(json['code']).to eq('record_invalid')
          expect(json['validation'][0]['emailConfirmation']).to eq('メールアドレス[確認]を正しく入力してください。')
        end
      end
    end

    context 'emailに変更がない場合' do
      let(:update_profile_attributes) do
        {
          'familyName' => '競輪',
          'givenName' => '太郎',
          'familyNameKana' => 'ケイリン',
          'givenNameKana' => 'タロウ',
          'birthday' => '2021-01-01T00:00:00+00:00',
          'email' => email,
          'email_confirmation' => email_confirmation,
          'mailmagazine' => 'false'
        }
      end
      let(:email) { sales_logged_in_user.profile.email }

      context 'email_confirmationがemailと同じ場合' do
        let(:email_confirmation) { email }

        it 'emailが更新されず、ステータス200が返ってくること' do
          expect { update_user }.not_to change { sales_logged_in_user.profile.reload.email }
          expect(response).to have_http_status(:ok)
        end
      end

      context 'email_confirmationがemailと異なる場合' do
        let(:email_confirmation) { 'email' }

        it 'emailが更新されずに、エラーが返ってくること' do
          expect { update_user }.not_to change { sales_logged_in_user.profile.reload.email }
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(json['code']).to eq('record_invalid')
          expect(json['validation'][0]['emailConfirmation']).to eq('メールアドレス[確認]を正しく入力してください。')
        end
      end
    end
  end

  describe 'auth_codeの発行と認証メールの送信', :sales_logged_in do
    subject(:send_auth_code) do
      perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
        put sales_send_auth_code_url, params: { profiles: update_profile_attributes }
      end
    end

    context '現在と同じemailが入力された場合' do
      let(:update_profile_attributes) do
        { 'email' => sales_logged_in_user.profile.email, 'email_confirmation' => sales_logged_in_user.profile.email }
      end

      it 'HTTPステータスが200であること' do
        send_auth_code
        expect(response).to have_http_status(:ok)
      end

      it 'email_auth_codeとemail_auth_expired_atが更新されること' do
        expect { send_auth_code }.to change { sales_logged_in_user.reload.email_auth_code }.and change { sales_logged_in_user.reload.email_auth_expired_at }
      end

      it 'emailが更新されないこと' do
        expect { send_auth_code }.not_to change { sales_logged_in_user.reload.profile.email }
        expect { send_auth_code }.not_to change { sales_logged_in_user.reload.profile.updated_at }
      end

      it 'メールが送信されること' do
        perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
          expect { send_auth_code }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
        expect(ActionMailer::Base.deliveries.map(&:to)).to include [sales_logged_in_user.reload.profile.email]
        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】メール認証をお済ませください'
      end
    end

    context 'emailが新しく正しい形式で入力されている場合' do
      let(:update_profile_attributes) do
        { 'email' => 'new_good@example.com', 'email_confirmation' => 'new_good@example.com' }
      end

      it 'emailが更新されて、認証メールが送信されること' do
        expect { send_auth_code }.to change { sales_logged_in_user.reload.profile.email }.from(sales_logged_in_user.profile.email).to(update_profile_attributes['email'])
        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】メール認証をお済ませください'
      end
    end

    context 'emailが正しくない形式で入力されている場合' do
      let(:update_profile_attributes) do
        { 'email' => 'bad@example', 'email_confirmation' => 'bad@example' }
      end

      it 'emailが更新されず、認証メールも送信されないこと' do
        expect { send_auth_code }.not_to change { sales_logged_in_user.reload.profile.email }
        expect(ActionMailer::Base.deliveries.count).to eq 0
      end
    end

    context 'emailが空欄の場合' do
      let(:update_profile_attributes) do
        { 'email' => '', 'email_confirmation' => '' }
      end

      it 'emailが更新されず、認証メールも送信されないこと' do
        expect { send_auth_code }.not_to change { sales_logged_in_user.reload.profile.email }
        expect(ActionMailer::Base.deliveries.count).to eq 0
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('メールアドレスを正しく入力してください')
      end
    end

    context 'emailが認証済みの場合' do
      before { sales_logged_in_user.update!(email_verified: true) }

      let(:update_profile_attributes) do
        { 'email' => sales_logged_in_user.profile.email, 'email_confirmation' => sales_logged_in_user.profile.email }
      end

      it 'emailが更新されず、認証メールも送信されないこと' do
        expect { send_auth_code }.not_to change { sales_logged_in_user.reload.profile.email }
        expect(ActionMailer::Base.deliveries.count).to eq 0
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('既に認証済みです')
      end
    end
  end

  describe '認証有効化', :sales_logged_in do
    subject(:email_verify) { put sales_email_verify_url(uuid: user.email_auth_code) }

    let(:user) do
      sales_logged_in_user.update(email_auth_code: 'test', email_auth_expired_at: Time.zone.now + 1.day)
      sales_logged_in_user
    end

    it 'HTTPステータスが200であること' do
      email_verify
      expect(response).to have_http_status(:ok)
    end

    it 'email_verified変更される、ユーザーのデータが返ること' do
      expect { email_verify }.to change { user.reload.email_verified }.from(false)
      json_body = JSON.parse(response.body)
      expect(json_body['id']).to eq(user.id)
    end

    context '認証期間が過ぎた場合' do
      let(:user) { create(:user, :with_profile, email_auth_code: 'email_auth_code', email_auth_expired_at: Time.zone.now - 1.day) }

      it '「認証期間が過ぎました」のエラーが返ること' do
        email_verify
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'expired', 'detail' => '認証期間が過ぎました', 'status' => 400 })
      end
    end

    context 'ユーザーが見付からない場合' do
      it '「not_found」のエラーが返ること' do
        put sales_email_verify_url(uuid: 'test')
        expect(response.body).to include 'not_found'
      end
    end
  end

  describe 'PATCH sales/users/:uuid/unsubscribe' do
    subject(:put_user_unsubscribe) { put sales_user_unsubscribe_url(unsubscribe_uuid: unsubscribe_uuid) }

    context 'uuidに該当するユーザーでログインしている場合', :sales_logged_in do
      before do
        sales_logged_in_user.unsubscribe_uuid = 'logged_in_user_unsubscribe_uuid'
        sales_logged_in_user.save
      end

      let(:unsubscribe_uuid) { 'logged_in_user_unsubscribe_uuid' }

      it 'http_status 200が返ってくること' do
        put_user_unsubscribe
        expect(response).to have_http_status(:ok)
      end

      it 'ログインユーザーのdeleted_atカラムが追加または更新されること' do
        expect { put_user_unsubscribe }.to change { sales_logged_in_user.reload.deleted_at }
      end

      it '退会完了メールが送信されること' do
        expect { perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) { put_user_unsubscribe } }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.map(&:to)).to include [sales_logged_in_user.profile.email]
        expect(ActionMailer::Base.deliveries.first.subject).to eq '【PIST6】退会手続きが完了しました'
      end
    end

    context 'uuidが存在しない場合' do
      let(:unsubscribe_uuid) { 'not_exist_unsubscribe_uuid' }

      it '「該当するユーザーが存在しません」のエラーが返ってくること' do
        put_user_unsubscribe
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'user_not_exist', 'detail' => '該当するユーザーが存在しません', 'status' => 400 })
      end
    end

    context 'ログインユーザーでないユーザーのunsubscribe_uuidが入力された場合', :sales_logged_in do
      before do
        sales_logged_in_user.unsubscribe_uuid = 'logged_in_user_unsubscribe_uuid'
        sales_logged_in_user.save
      end

      let(:other_user) { create(:user, unsubscribe_uuid: 'other_user_unsubscribe_uuid') }
      let(:unsubscribe_uuid) { other_user.unsubscribe_uuid }

      it '「ユーザー本人以外ではこの処理は無効です」のエラーメッセージが返ってくること' do
        put_user_unsubscribe
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'different_uuid', 'detail' => 'ユーザー本人以外ではこの処理は無効です', 'status' => 401 })
      end

      it 'deleted_atの値が変化しないこと' do
        expect { put_user_unsubscribe }.not_to change { sales_logged_in_user.reload.deleted_at }
        expect { put_user_unsubscribe }.not_to change { other_user.reload.deleted_at }
      end
    end

    context '未ログイン状態の場合' do
      let(:target_user) { create(:user, unsubscribe_uuid: 'target_user_unsubscribe_uuid') }
      let(:unsubscribe_uuid) { target_user.unsubscribe_uuid }

      it '「ログインしてください」のエラーメッセージが返ってくること' do
        put_user_unsubscribe
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'login_required', 'detail' => 'ログインしてください', 'status' => 401 })
      end

      it 'deleted_atの値が変化しないこと' do
        expect { put_user_unsubscribe }.not_to change { target_user.reload.deleted_at }
      end
    end

    context 'すでに退会済みの場合', :sales_logged_in do
      before do
        sales_logged_in_user.unsubscribe_uuid = 'logged_in_user_unsubscribe_uuid'
        sales_logged_in_user.deleted_at = '2020-1-1 00:00:00'
        sales_logged_in_user.save
      end

      let(:unsubscribe_uuid) { sales_logged_in_user.unsubscribe_uuid }

      it '「すでに退会済みです」のエラーが返ってくること' do
        put_user_unsubscribe
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'deleted_user', 'detail' => 'すでに退会済みです', 'status' => 400 })
      end
    end
  end

  describe 'GET sales/users/mixi_m_callback' do
    subject(:mixi_m_callback) do
      allow(LoginRequiredUuid).to receive(:generate_uuid).and_return(random_uuid)
      get sales_users_url
      get sales_users_mixi_m_callback_url(code: code, state: state)
    end

    context 'コード,stateを送信した時' do
      let(:code) { '08012345678' }
      let(:state) { '123' }
      let(:random_uuid) { '123' }

      context 'ユーザー登録済みの場合' do
        let(:user) { create(:user, :with_profile, sixgram_id: code) }

        it 'ユーザー登録済みを示すレスポンスが返ること' do
          user_id = user.id
          mixi_m_callback
          json = JSON.parse(response.body)
          expect(json['registered']).to be true
          expect(json['currentUser']['id']).to eq(user_id)
          expect(json['migrationRequired']).to be false
        end

        it 'ユーザーセッションが作成されていること' do
          mixi_m_callback
          expect(session[:user_auth_token].present?).to be true
        end

        it 'セッションに電話番号が入っていること' do
          mixi_m_callback
          expect(session[:phone_number]).to eq('08012345678')
        end
      end

      context 'ユーザー未登録の場合' do
        it 'ユーザー未登録を示すレスポンスが返ること' do
          mixi_m_callback
          json = JSON.parse(response.body)
          expect(json['registered']).to be false
        end

        it 'ユーザーセッションが作成されていること' do
          mixi_m_callback
          expect(session[:user_auth_token].present?).to be true
        end
      end

      it '6gramにマイグレーションチェックのAPIが一回しか呼ばれていないこと' do
        allow(Sixgram::Service).to receive(:get_migration_validate)

        mixi_m_callback
        expect(Sixgram::Service).to have_received(:get_migration_validate).once
      end

      context 'ユーザーが退会済みの場合' do
        before do
          create(:user, :with_profile, sixgram_id: code, deleted_at: Time.zone.now)
        end

        it 'ユーザー退会済みを示すレスポンスが返ること' do
          mixi_m_callback
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:forbidden)
          expect(json['code']).to eq('unsubscribed_user_error')
          expect(json['detail']).to eq('アカウントは退会済みです')
        end

        it 'セッションがリセットされていること' do
          mixi_m_callback
          expect(session[:user_auth_token].blank?).to be true
          expect(session[:access_token].blank?).to be true
          expect(session[:refresh_token].blank?).to be true
        end
      end
    end

    context 'コードを未送信の場合' do
      let(:code) { nil }
      let(:state) { '123' }
      let(:random_uuid) { '123' }

      it 'ログインしてくださいのエラーが発生すること' do
        mixi_m_callback
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['code']).to eq('login_required')
        expect(json['detail']).to eq('MIXI Mでログインしてください')
      end

      it 'ユーザーセッションが作成されていないこと' do
        mixi_m_callback
        expect(session[:user_auth_token].present?).to be false
      end
    end

    context 'stateを未送信の場合' do
      let(:code) { '08012345678' }
      let(:state) { nil }
      let(:random_uuid) { '123' }

      it 'ログインしてくださいのエラーが発生すること' do
        mixi_m_callback
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:unauthorized)
        expect(json['code']).to eq('invalid_sixgram_user_auth_error')
        expect(json['detail']).to eq('ユーザー認証に失敗しました')
      end

      it 'ユーザーセッションが作成されていないこと' do
        mixi_m_callback
        expect(session[:user_auth_token].present?).to be false
      end
    end
  end

  describe 'GET sales/users/migration_apply', :sales_logged_in do
    subject(:migration_apply) { get sales_users_migration_apply_url }

    context '正常時' do
      let(:sales_logged_in_user_code) { '08012345678' }

      it 'OKのステータスが返ること' do
        migration_apply
        expect(response).to have_http_status(:ok)
      end
    end

    context '移行済みユーザーの場合' do
      let(:sales_logged_in_user_code) { '09000060001' }

      it 'エラーが発生すること' do
        migration_apply
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('custom_error')
      end
    end

    context '自動的に解決できない競合が発生しているユーザーの場合' do
      let(:sales_logged_in_user_code) { '09000060002' }

      it 'エラーが発生すること' do
        migration_apply
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('invalid_migration_error')
      end
    end
  end

  describe 'GET sales/users/qr_code', :sales_logged_in do
    before do
      get sales_user_qr_code_url
    end

    it 'qr_user_idが取得できている事' do
      json = JSON.parse(response.body)
      expect(json['qrUserId']).to eq(sales_logged_in_user.qr_user_id)
    end
  end
end
