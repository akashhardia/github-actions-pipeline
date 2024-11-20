# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CognitoController', type: :request do
  describe 'POST admin/login' do
    subject(:login) { post admin_login_url(params) }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { email: 'test', password: 'test' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context 'loginに成功した場合' do
      before do
        allow(client).to receive(:admin_initiate_auth).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it 'ログインセッションが作成されること' do
        login
        expect(session[:admin_jwt]).to eq('id_token')
        expect(session[:admin_refresh_token]).to eq('refresh_token')
        json = JSON.parse(response.body)
        expect(json).to eq({ 'status' => 'logged_in' })
      end

      it 'ログイン前はadminリソースにアクセスできないこと' do
        get admin_template_seat_sales_url, params: params
      end
    end

    context '入力値が不正だった場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::InvalidParameterException.new('context', 'error')
        allow(client).to receive(:admin_initiate_auth).and_raise(error)
      end

      it 'code: cognito_login_errorが返されること' do
        login
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => '入力値が不正です', 'status' => 400 })
      end
    end

    context 'メールアドレス、またはパスワードが間違っていた場合' do
      before do
        error = Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new('context', 'error')
        allow(client).to receive(:admin_initiate_auth).and_raise(error)
      end

      it 'code: cognito_login_errorが返されること' do
        login
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'cognito_login_error', 'detail' => 'メールアドレス、またはパスワードが間違っています。もう一度入力してください', 'status' => 400 })
      end
    end
  end

  describe 'DELETE admin/logout' do
    subject(:logout) { delete admin_logout_url }

    before do
      allow(Cognito::Service).to receive(:client).and_return(client)
    end

    let(:params) { { email: 'test', password: 'test' } }
    let(:client) do
      Aws::CognitoIdentityProvider::Client.new(
        region: 'region',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key'
      )
    end

    context 'logoutに成功した場合' do
      before do
        allow(client).to receive(:admin_initiate_auth).and_return(cognito_response)
        post admin_login_url(params)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: 'refresh_token') }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      it 'ログインセッションが削除されること' do
        expect(session[:admin_jwt]).to eq('id_token')
        expect(session[:admin_refresh_token]).to eq('refresh_token')
        logout
        expect(session[:admin_jwt]).to eq(nil)
        expect(session[:admin_refresh_token]).to eq(nil)
      end
    end
  end
end
