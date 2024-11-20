# frozen_string_literal: true

module Sales
  # salesのApplicationControllerです
  class ApplicationController < ::ApplicationController
    include PortalLogin
    before_action :require_login!

    def ng_user_check
      raise LoginRequiredError, I18n.t('custom_errors.login_required_errors.input_phone_number') if session[:user_auth_token].blank?

      begin
        NgUserChecker.new(session[:user_auth_token]).validate!
      rescue StandardError
        reset_session
        raise NgUserError, I18n.t('custom_errors.messages.ng_user_error')
      end
    end
  end
end
