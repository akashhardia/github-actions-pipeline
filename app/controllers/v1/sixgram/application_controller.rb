# frozen_string_literal: true

module V1
  module Sixgram
    # SixgramModuleApplicationController
    class ApplicationController < V1::ApplicationController
      def webhook_auth
        raise CustomError.new(http_status: :unauthorized), I18n.t('api_errors.sixgram.webhook_token_mismatch') unless request.headers['X-Webhook-Token'] == CredentialHelper.sixgram_payment[:x_webhook_token]
      end
    end
  end
end
