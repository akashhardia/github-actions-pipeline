# frozen_string_literal: true

module Admin
  # 管理ユーザーコントローラー
  class AdminUsersController < ApplicationController
    before_action :snakeize_params
    skip_before_action :require_login!, only: :confirm_sign_up

    def sign_up
      ApiProvider.cognito.sign_up(name: params[:name], email: params[:email], password: params[:password])
      head :ok
    end

    def confirm_sign_up
      ApiProvider.cognito.confirm_sign_up(email: params[:email], confirmation_code: params[:code])
      head :ok
    end

    def forgot_password
      ApiProvider.cognito.forgot_password(email: params[:email])
      head :ok
    end

    def confirm_forgot_password
      ApiProvider.cognito.confirm_forgot_password(email: params[:email], confirmation_code: params[:code], password: params[:password])
      head :ok
    end

    def index
      users = ApiProvider.cognito.admin_user_list
      render json: users, root: 'admin_users', each_serializer: Admin::AdminUserSerializer, key_transform: :camel_lower
    end

    def admin_enable_user
      ApiProvider.cognito.admin_enable_user(email: params[:email])
      head :ok
    end

    def admin_disable_user
      ApiProvider.cognito.admin_disable_user(email: params[:email])
      head :ok
    end
  end
end
