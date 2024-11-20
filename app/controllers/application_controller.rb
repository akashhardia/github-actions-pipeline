# frozen_string_literal: true

# controllerで発生する各例外をキャッチしています
class ApplicationController < ActionController::API
  using ParamsSnakeizer
  include Pagination

  # ActiveModelSerializersから不必要にcurrent_userメソッドをコールされてしまう問題の対策
  serialization_scope :view_context

  rescue_from Exception, with: :render500
  rescue_from CustomError, with: :render_custom
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error
  rescue_from ActionController::BadRequest, with: :render400
  rescue_from ActionController::RoutingError, with: :render404
  rescue_from ActiveRecord::RecordNotFound, with: :render404

  def render_error(error)
    @error = error

    render json: { code: error.code, detail: error.message, status: error.http_status_code }, status: error.http_status
  end

  def render_custom(error = nil)
    session[:user_auth_token]&.clear if error.is_a?(LoginRequiredError)
    to_logs(error, "Rendering #{error.http_status_code}") if error

    render_error(error)
  end

  def render400(error = nil)
    to_logs(error, 'Rendering 400') if error

    render_error(::CustomError.new(http_status: :bad_request, code: 'bad_request'))
  end

  def render404(error = nil)
    to_logs(error, 'Rendering 404') if error

    render_error(::CustomError.new(http_status: :not_found, code: 'not_found'))
  end

  def render500(error = nil)
    to_logs(error, 'Rendering 500') if error

    render_error(::CustomError.new(http_status: :internal_server_error, code: 'internal_server_error'))
  end

  def render_validation_error(error)
    to_logs(error, 'Rendering 400') if error

    validation_errors =
      error.record.errors.as_json(full_messages: true).map do |key, value|
        { key.to_s.camelize(:lower) => value[0] }
      end

    e = ::CustomError.new(http_status: :bad_request, code: 'record_invalid')

    render json: { code: e.code, detail: e.message, validation: validation_errors, status: e.http_status_code }, status: e.http_status
  end

  def to_logs(error, description)
    logger.error "#{description} with exception: #{error.inspect}"
    logger.info error.backtrace.join("\n") unless Rails.env.production? || Rails.env.test? || Rails.env.staging?
    @exception = error
  end

  def snakeize_params
    params.deep_snakeize!
  end

  def prevent_double_submit_with_id!(id, &block)
    lock = Redis::Lock.new("#{id} :prevent_double_submit", expiration: 30, timeout: 30)
    lock.lock(&block)
  end

  def append_info_to_payload(payload)
    super
    payload[:ip] = request.remote_ip
    payload[:referer] = request.referer
    payload[:user_agent] = request.user_agent
    payload[:login_id] = session[:login_id]
    payload[:request_id] = request.request_id
    return if @exception.blank?

    payload[:exception_object] ||= @exception
    payload[:exception] ||= [@exception.class.name, @exception.message]
  end
end
