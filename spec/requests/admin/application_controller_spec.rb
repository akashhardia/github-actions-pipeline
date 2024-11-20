# frozen_string_literal: true

require 'rails_helper'

# ApplicationControllerやconcernのテスト用
describe ApplicationController, type: :controller do
  describe 'CognitoTokenAuth' do
    controller do
      include CognitoTokenAuth

      before_action :require_login!

      def index
        render nothing: true
      end
    end

    context 'ログインしていない場合' do
      it 'ログイン必須エラーが出ること' do
        get :index
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'login_required', 'detail' => 'ログインしてください', 'status' => 401 })
      end
    end

    context 'refresh_tokenが有効期限内の場合', :admin_jwt_mock do
      before do
        session[:admin_jwt] = jwt
        session[:admin_refresh_token] = +'refresh_token'
        allow(Cognito::Service).to receive(:client).and_return(client)
        allow(client).to receive(:admin_initiate_auth).and_return(cognito_response)
      end

      let(:auth_result) { OpenStruct.new(id_token: 'id_token', refresh_token: nil) }
      let(:cognito_response) { OpenStruct.new(challenge_name: nil, session: nil, authentication_result: auth_result) }

      let(:client) do
        Aws::CognitoIdentityProvider::Client.new(
          region: 'region',
          access_key_id: 'access_key_id',
          secret_access_key: 'secret_access_key'
        )
      end
      let(:exp) { (Time.zone.now - 1.hour).to_i }

      it 'ユーザー認証エラーは出ず、jwtが更新されること' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(session[:admin_jwt]).to eq('id_token')
        expect(session[:admin_jwt]).not_to eq(jwt)
      end
    end

    context 'refresh_tokenが有効期限切れの場合', :admin_jwt_mock do
      before do
        session[:admin_jwt] = jwt
        session[:admin_refresh_token] = +'refresh_token'
        allow(Cognito::Service).to receive(:client).and_return(client)
        error = Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new('context', 'Refresh Token has expired')
        allow(client).to receive(:admin_initiate_auth).and_raise(error)
      end

      let(:client) do
        Aws::CognitoIdentityProvider::Client.new(
          region: 'region',
          access_key_id: 'access_key_id',
          secret_access_key: 'secret_access_key'
        )
      end
      let(:exp) { (Time.zone.now - 1.hour).to_i }

      it 'ユーザー認証エラーが出ること' do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'invalid_cognito_token_error', 'detail' => 'ユーザー認証に失敗しました', 'status' => 401 })
      end
    end
  end
end
