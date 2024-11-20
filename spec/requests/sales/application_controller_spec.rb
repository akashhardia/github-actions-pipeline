# frozen_string_literal: true

require 'rails_helper'

# ApplicationControllerやconcernのテスト用
describe Sales::ApplicationController, type: :controller do
  describe 'PortalLogin' do
    controller do
      include PortalLogin

      before_action :require_login!

      def index
        render json: { current_user_id: current_user&.id }
      end
    end

    context 'ログインしていない場合' do
      it 'ログイン必須エラーが出ること' do
        get :index
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'login_required', 'detail' => 'ログインしてください', 'status' => 401 })
      end
    end

    context 'ログイン済み', :sales_jwt_mock do
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:session).and_return({ user_auth_token: sixgram_access_token }) # rubocop:disable RSpec/AnyInstance
      end

      context 'JWT期限内の場合' do
        it 'ログインユーザーの情報が返ってくること' do
          get :index
          json = JSON.parse(response.body)
          expect(json['current_user_id']).to eq(sales_jwt_mock_user.id)
        end
      end

      context 'JWT期限切れの場合' do
        let(:sixgram_access_token_exp) { (Time.zone.now - 1.day).to_i }

        it 'LoginRequiredErrorが発生すること' do
          get :index
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:unauthorized)
          expect(json['detail']).to eq('もう一度ログインしてください')
        end
      end

      context '不正なJWTだった場合' do
        let(:sixgram_access_token_key) { SecureRandom.uuid }

        it 'LoginRequiredErrorが発生すること' do
          get :index
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:unauthorized)
          expect(json['detail']).to eq('ユーザー認証に失敗しました')
        end
      end
    end
  end

  describe '#ng_user_check' do
    controller do
      skip_before_action :require_login!
      before_action :ng_user_check

      def index
        render json: { current_user_id: current_user&.id }
      end
    end

    context 'ログインしていない場合' do
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:session).and_return({ user_auth_token: nil }) # rubocop:disable RSpec/AnyInstance
      end

      it 'LoginRequiredErrorが発生すること' do
        get :index
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:unauthorized)
        expect(json['detail']).to eq('もう一度電話番号を入力してください')
      end
    end

    context 'ログイン済み', :sales_jwt_mock do
      before do
        allow_any_instance_of(ActionDispatch::Request).to receive(:session).and_return({ user_auth_token: sixgram_access_token }) # rubocop:disable RSpec/AnyInstance
        allow(NgUserChecker).to receive(:new).and_return(mock_ng_user_checker)
      end

      let(:mock_ng_user_checker) { instance_double(NgUserChecker) }

      context 'アカウントが無効の場合' do
        before do
          allow(mock_ng_user_checker).to receive(:validate!).and_raise(StandardError)
        end

        it 'NgUserErrorが発生すること' do
          get :index
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:forbidden)
          expect(json['detail']).to eq('アカウントが無効です')
        end
      end

      context 'アカウントが有効の場合', :sales_jwt_mock do
        before do
          allow(mock_ng_user_checker).to receive(:validate!).and_return(true)
        end

        it 'エラーが発生しないこと' do
          get :index
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
