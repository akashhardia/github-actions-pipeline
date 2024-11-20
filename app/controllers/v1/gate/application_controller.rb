# frozen_string_literal: true

module V1
  module Gate
    # GateのApplicationControllerです
    class ApplicationController < V1::ApplicationController
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate

      private

      def authenticate
        authenticate_token || render_unauthorized
      end

      def authenticate_token
        authenticate_with_http_token do |token, _options|
          token == CredentialHelper.gate_250[:api_token]
        end
      end

      def render_unauthorized
        # TODO: 認証エラー時のレスポンスについては要確認
        render json: { message: 'token invalid' }, status: :unauthorized
      end
    end
  end
end
