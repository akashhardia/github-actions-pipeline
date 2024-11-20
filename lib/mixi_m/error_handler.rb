# frozen_string_literal: true

module MixiM
  # APIのレスポンスに応じたエラーハンドリングを行う
  class ErrorHandler
    class << self
      def handle_user_auth_error(_method_name, result)
        Rails.logger.error "handle_user_auth_error_result #{result}"
        error_code = result['error']
        raise LoginRequiredError, I18n.t('custom_errors.login_required_errors.login_again') if %w[invalid_client invalid_request invalid_grant].include?(error_code)

        error_detail = "status: #{result.response.code}, code: #{error_code}, description: #{result['description']}"
        Rails.logger.fatal "MixiMUserAuthError #{error_detail}"
        raise FatalMixiMApiError, I18n.t('custom_errors.messages.error_occured')
      end

      def handle_user_access_error(result)
        Rails.logger.error "handle_user_access_error_result #{result}"
        error_code = result['error']
        raise LoginRequiredError, I18n.t('custom_errors.login_required_errors.login_again') if %w[invalid_client invalid_request invalid_grant].include?(error_code)

        error_detail = "status: #{result.response.code}, error: #{error_code}, error_description: #{result['error_description']}}"
        Rails.logger.error "MixiMUserAccessError #{error_detail}"
        raise InvalidMixiMUserAuthError, I18n.t('custom_errors.messages.error_occured')
      end
    end
  end
end
