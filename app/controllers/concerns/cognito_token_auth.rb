# frozen_string_literal: true

# adminのユーザーsession確認
module CognitoTokenAuth
  extend ActiveSupport::Concern

  def require_login!
    jwt = session[:admin_jwt]

    raise LoginRequiredError, I18n.t('custom_errors.messages.login_required_error') if jwt.blank?

    begin
      _uid = Cognito::Certification.verify_jwt!(jwt)
    rescue JWT::ExpiredSignature
      result = ApiProvider.cognito.token_refresh(session[:admin_refresh_token])

      unless result[:succeed]
        Rails.logger.error "InvalidCognitoTokenError: #{result[:message]}"
        clear_session
        raise InvalidCognitoTokenError, I18n.t('custom_errors.users.auth_failed')
      end

      session[:admin_jwt] = result[:jwt]
    rescue StandardError => e
      Rails.logger.error "InvalidCognitoTokenError: #{e}"
      clear_session
      raise InvalidCognitoTokenError, I18n.t('custom_errors.users.auth_failed')
    end
  end

  def check_session
    jwt = session[:admin_jwt]

    return false if jwt.blank?

    begin
      Cognito::Certification.verify_jwt!(jwt)
      true
    rescue StandardError
      clear_session
      false
    end
  end

  def clear_session
    session[:admin_jwt]&.clear
    session[:admin_refresh_token]&.clear
  end
end
