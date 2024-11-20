# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminUsersController', :admin_logged_in, type: :request do
  describe 'POST admin_users/sign_up' do
    subject(:sign_up) { post admin_admin_user_sign_up_url(params) }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { name: 'test', email: 'test@test.com', password: 'test' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context '管理ユーザーの作成' do
      before do
        allow(client).to receive(:sign_up).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it '作成されることを確認' do
        sign_up
        expect(response).to have_http_status(:ok)
      end
    end

    context '入力値が不正だった場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::InvalidParameterException.new('context', 'error')
        allow(client).to receive(:sign_up).and_raise(error)
      end

      it 'エラーメッセージが返されること' do
        sign_up
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => '入力値が不正です', 'status' => 400 })
      end
    end

    context 'パスワードの入力形式に違反していた場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::InvalidPasswordException.new('context', 'error')
        allow(client).to receive(:sign_up).and_raise(error)
      end

      it 'エラーメッセージが返されること' do
        sign_up
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => 'パスワードは8文字以上、大文字、小文字を含む半角英数で指定してください', 'status' => 400 })
      end
    end
  end

  describe 'POST admin_users/confirm_sign_up' do
    subject(:confirm_sign_up) { post admin_admin_user_confirm_sign_up_url(params) }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { email: 'test@test.com', code: '123456' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context '確認コード検証' do
      before do
        allow(client).to receive(:confirm_sign_up).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it '検証ができることを確認' do
        confirm_sign_up
        expect(response).to have_http_status(:ok)
      end
    end

    context 'emailまたはコード値が不正の場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new('context', 'error')
        allow(client).to receive(:confirm_sign_up).and_raise(error)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it 'エラーメッセージが返されること' do
        confirm_sign_up
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => 'emailまたはコード値が不正です', 'status' => 400 })
      end
    end
  end

  describe 'GET admin/admin_users' do
    subject(:admin_users_index) { get admin_admin_users_url }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context 'エラーなく一覧が表示されること' do
      before do
        allow(client).to receive(:list_users).and_return(cognito_response)
      end

      let(:sub_attr) { OpenStruct.new(name: 'sub', value: 'test_user') }
      let(:name) { OpenStruct.new(name: 'name', value: 'test_user') }
      let(:email_verified) { OpenStruct.new(name: 'email_verified', value: 'true') }
      let(:email) { OpenStruct.new(name: 'email', value: 'test_user@test.com') }
      let(:admin_user) do
        OpenStruct.new(
          username: '0bec010b-15c6-2110-434c-c3685690beg7',
          attributes: [sub_attr, name, email_verified, email],
          user_create_date: Time.zone.now,
          user_last_modified_date: Time.zone.now,
          enabled: true,
          user_status: 'CONFIRMED'
        )
      end
      let(:cognito_response) { OpenStruct.new(users: [admin_user]) }

      it '一覧のレスポンスが返ること' do
        admin_users_index
        json = JSON.parse(response.body)
        expect(json[0]['uuid']).to eq(admin_user.username)
        expect(json[0]['name']).to eq(name.value)
        expect(json[0]['emailVerified']).to eq(email_verified.value)
        expect(json[0]['email']).to eq(email.value)
        expect(json[0]['enabled']).to eq(admin_user.enabled)
        expect(json[0]['userStatus']).to eq(admin_user.user_status)
        expect(json[0]['userCreateDate']).to eq(admin_user.user_create_date.strftime('%Y-%m-%d %H:%M:%S'))
        expect(json[0]['userLastModifiedDate']).to eq(admin_user.user_last_modified_date.strftime('%Y-%m-%d %H:%M:%S'))
      end
    end
  end

  describe 'PUT admin_users/admin_enable_user' do
    subject(:admin_enable_user) { put admin_admin_user_admin_enable_user_url(params) }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { email: 'test@test.com' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context '正常なパラメータの場合' do
      before do
        allow(client).to receive(:admin_enable_user).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it '有効化されること' do
        admin_enable_user
        expect(response).to have_http_status(:ok)
      end
    end

    context '該当するメールアドレスが存在しない場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new('context', 'error')
        allow(client).to receive(:admin_enable_user).and_raise(error)
      end

      it 'エラーが返されること' do
        admin_enable_user
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => '対象のユーザーが見つかりません', 'status' => 400 })
      end
    end
  end

  describe 'PUT admin_users/admin_disable_user' do
    subject(:admin_disable_user) { put admin_admin_user_admin_disable_user_url(params) }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { email: 'test@test.com' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context '正常なパラメータの場合' do
      before do
        allow(client).to receive(:admin_disable_user).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it '無効化されること' do
        admin_disable_user
        expect(response).to have_http_status(:ok)
      end
    end

    context '該当するメールアドレスが存在しない場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new('context', 'error')
        allow(client).to receive(:admin_disable_user).and_raise(error)
      end

      it 'エラーが返されること' do
        admin_disable_user
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => '対象のユーザーが見つかりません', 'status' => 400 })
      end
    end
  end
end
