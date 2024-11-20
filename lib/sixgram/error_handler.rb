# frozen_string_literal: true

module Sixgram
  # APIのレスポンスに応じたエラーハンドリングを行う
  class ErrorHandler
    class << self
      def handle_user_auth_error(method_name, result)
        Rails.logger.error "handle_user_auth_error_result #{result}"
        error_code = result['error']

        handle_client_auth_error(response) if error_code == 'client_auth_failed'

        raise LoginRequiredError, I18n.t("api_errors.sixgram.#{method_name}.#{error_code}") if %w[invalid_verify_token expired_auth_code].include?(error_code)

        if I18n.exists?("api_errors.sixgram.#{method_name}.#{error_code}")
          code = birthday_confirmation_required?(error_code) ? 'custom_error' : 'invalid_params'
          raise CustomError.new(http_status: :bad_request, code: code), I18n.t("api_errors.sixgram.#{method_name}.#{error_code}")
        end

        error_detail = "status: #{result.response.code}, code: #{error_code}, description: #{result['description']}"
        Rails.logger.fatal "SixgramUserAuthError #{error_detail}"
        raise FatalSixgramApiError, I18n.t('custom_errors.messages.error_occured')
      end

      def handle_user_access_error(result)
        Rails.logger.error "handle_user_access_error_result #{result}"
        error_code = result['error']
        raise LoginRequiredError, I18n.t('custom_errors.login_required_errors.login_again') if %w[token_expired auth_token_expired invalid_user].include?(error_code)

        error_detail = "status: #{result.response.code}, error: #{error_code}, error_description: #{result['error_description']}, user_id: #{result['user_id']}"
        Rails.logger.error "SixgramUserAccessError #{error_detail}"
        raise InvalidSixgramUserAuthError, I18n.t('custom_errors.messages.error_occured')
      end

      def handle_client_auth_error(response)
        Rails.logger.fatal "FatalSixgramClientAuthError #{response['error']} #{response['description']}"
        raise FatalSixgramClientAuthError, I18n.t('api_errors.sixgram.client_auth_failed', description: response['description'])
      end

      def handle_user_migration_error(result)
        Rails.logger.error "handle_user_access_error_result #{result}"
        error_code = result['error']
        raise CustomError.new(http_status: :bad_request), I18n.t('api_errors.sixgram.already_migrated') if %w[already_migrated].include?(error_code)
        raise InvalidMigrationError.new, I18n.t('api_errors.sixgram.need_contact') if %w[need_contact].include?(error_code)

        error_detail = "status: #{result.response.code}, error: #{error_code}, error_description: #{result['error_description']}, user_id: #{result['user_id']}"
        Rails.logger.error "SixgramUserAccessError #{error_detail}"
        raise InvalidSixgramUserAuthError, I18n.t('api_errors.sixgram.error_occured')
      end

      private

      # 生年月日の確認が必要なエラーかどうか
      def birthday_confirmation_required?(error_code)
        %w[birthdate_verification_required birthdate_verification_unavailable lockout_birthdate_verification].include?(error_code)
      end
    end
  end
end
