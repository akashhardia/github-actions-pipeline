# frozen_string_literal: true

# カスタムエラーを作成する場合
# module SampleErrors
#   class SampleError < CustomError
#     http_status :internal_server_error # => Rack::Utils::HTTP_STATUS_CODE の symbol を指定します
#
#     message :hoge # => message_key を override する場合に指定できます。指定しなければ モジュール名/クラス名でキーを検索します。 なければ http_status で検索します。
#   end
# end
#
class CustomError < StandardError
  attr_reader :http_status, :code

  def initialize(error_message = nil, http_status: nil, message_key: nil, code: nil)
    @http_status = http_status || self.class.http_status_or_default
    message = error_message || self.class.load_message(message_key, @http_status)
    @code = code || self.class.code_key || self.class.name.underscore.tr('/', '-')
    super(message)
  end

  def http_status_code
    Rack::Utils.status_code(http_status)
  end

  class << self
    attr_reader :http_status_symbol, :message_key, :code_key

    def load_message(message_key, http_status = nil)
      message_key ||= self.message_key
      message_key ||= default_key_from_class_name
      http_status ||= http_status_or_default
      raise 'unknown http status' unless http_status

      I18n.t("custom_errors.messages.#{message_key}", default: :"custom_errors.messages.#{http_status}")
    end

    def default_key_from_class_name
      name.split('::').map(&:underscore).join('.')
    end

    def http_status_or_default
      http_status_symbol || (:internal_server_error if Rails.env.production? || Rails.env.staging?)
    end

    private

    def http_status(status)
      @http_status_symbol = status
    end

    def message(message_key)
      @message_key = message_key
    end

    def code(code_key)
      @code_key = code_key
    end
  end
end
