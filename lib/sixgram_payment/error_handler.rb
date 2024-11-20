# frozen_string_literal: true

module SixgramPayment
  # APIのレスポンスに応じたエラーハンドリングを行う
  class ErrorHandler
    class << self
      def handle_error(method_name, result)
        Rails.logger.error "handle_error_result #{result}"
        error_code = result['error']

        # already_capturedの場合は戻る
        return if error_code == 'already_captured'

        # 実際のエラーがこのように入ってくるかは要確認
        error_detail = "status: #{result.response.code}, code: #{error_code}, context: #{method_name}, description: #{result['description']}, decline_code: #{result['decline_code']}"
        raise CustomError.new(http_status: :bad_request, code: error_code), error_detail if result.response.code.to_i < 500

        raise FatalSixgramPaymentError, I18n.t('api_errors.sixgram_payment.error_occured', error_detail: error_detail)
      end
    end
  end
end
