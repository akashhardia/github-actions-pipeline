# frozen_string_literal: true

module V1
  module Portal250
    # Portal250のApplicationControllerです
    class ApplicationController < ::ApplicationController
      private

      def authenticate_token
        authenticate_with_http_token do |token, _options|
          token == CredentialHelper.gate_250[:api_token] # TODO: ゲートアプリとポータルとで認証トークンを変更する予定
        end
      end
    end
  end
end
