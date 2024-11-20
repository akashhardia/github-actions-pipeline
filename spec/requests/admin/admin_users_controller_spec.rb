# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminUsersController', :admin_logged_in, type: :request do
  describe 'PUT admin_users/forgot_password' do
    subject(:forgot_password) { put admin_admin_user_forgot_password_url(params) }

    let(:params) { { email: 'test@test.com' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    context 'パスワードを忘れてメールでリセットした場合' do
      before do
        allow(client).to receive(:forgot_password).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it '認証コード送信確認' do
        forgot_password
        expect(response).to have_http_status(:ok)
      end
    end

    context '入力値が不正だった場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::InvalidParameterException.new('context', 'error')
        allow(client).to receive(:forgot_password).and_raise(error)
      end

      it 'code: cognito_login_errorが返されること' do
        forgot_password
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => '入力値が不正です', 'status' => 400 })
      end
    end
  end

  describe 'PUT admin_users/confirm_forgot_password' do
    subject(:confirm_forgot_password) { put admin_admin_user_confirm_forgot_password_url(params) }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { email: 'test@test.com', code: '123456', password: '0000Test' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context '新しいパスワードに変更しようとした場合' do
      before do
        allow(client).to receive(:confirm_forgot_password).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it '成功することを確認' do
        confirm_forgot_password
        expect(response).to have_http_status(:ok)
      end
    end

    context 'emailまたはコード値が不正だった場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new('context', 'error')
        allow(client).to receive(:confirm_forgot_password).and_raise(error)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it 'code: cognito_login_errorが返されること' do
        confirm_forgot_password
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => 'emailまたはコード値が不正です', 'status' => 400 })
      end
    end

    context 'パスワードのポリシーに違反していた場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::InvalidPasswordException.new('context', 'error')
        allow(client).to receive(:confirm_forgot_password).and_raise(error)
      end

      it 'code: cognito_login_errorが返されること' do
        confirm_forgot_password
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => 'パスワードは8文字以上、大文字、小文字を含む半角英数で指定してください', 'status' => 400 })
      end
    end

    context '対象のユーザーが見つからない場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new('context', 'error')
        allow(client).to receive(:confirm_forgot_password).and_raise(error)
      end

      it 'code: cognito_login_errorが返されること' do
        confirm_forgot_password
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => '対象のユーザーが見つかりません', 'status' => 400 })
      end
    end
  end
end
