# frozen_string_literal: true

module Admin
  # 管理画面ログイン
  class CognitoController < ApplicationController
    skip_before_action :require_login!

    def login_check
      result = check_session

      render json: { loggedIn: result }
    end

    def login
      email = params[:email]
      password = params[:password]
      result = ApiProvider.cognito.get_token(email, password)
      session[:admin_jwt] = result[:jwt]
      session[:admin_refresh_token] = result[:refresh_token]
      render json: { status: :logged_in }
    end

    def logout
      reset_session

      head :ok
    end
  end
end
