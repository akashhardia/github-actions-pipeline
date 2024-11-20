# frozen_string_literal: true

module Cognito
  # cognito api fetcher
  class Service < Credential
    class << self
      def client
        @client ||= Aws::CognitoIdentityProvider::Client.new(
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )
      end

      def get_token(email, password)
        res = client.admin_initiate_auth(
          user_pool_id: user_pool_id,
          client_id: client_id,
          auth_flow: 'ADMIN_NO_SRP_AUTH',
          auth_parameters: {
            USERNAME: email,
            PASSWORD: password
          }
        )
        # 仮パスワードだった場合は新しいパスワードへの変更を要求
        return { succeed: false, challenge_name: res.challenge_name, session: res.session } if res.challenge_name

        auth = res.authentication_result
        { succeed: true, jwt: auth.id_token, refresh_token: auth.refresh_token }
      rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException
        # example
        # Aws::CognitoIdentityProvider::Errors::InvalidParameterException: 2 validation errors detected:
        # Value 'hoge　example@example.com' at 'userName' failed to satisfy constraint: Member must satisfy regular expression pattern: [\p{L}\p{M}\p{S}\p{N}\p{P}]+;
        # Value 'hoge　example@example@example.com' at 'userAlias' failed to satisfy constraint: Member must satisfy regular expression pattern: [\p{L}\p{M}\p{S}\p{N}\p{P}]+>

        raise CognitoLoginError, I18n.t('api_errors.cognito.invalid_params')
      rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
        raise CognitoLoginError, I18n.t('api_errors.cognito.not_authorized')
      end

      def token_refresh(refresh_token)
        res = client.admin_initiate_auth(
          user_pool_id: user_pool_id,
          client_id: client_id,
          auth_flow: 'REFRESH_TOKEN_AUTH',
          auth_parameters: {
            REFRESH_TOKEN: refresh_token
          }
        )

        { succeed: true, jwt: res.authentication_result.id_token }
      rescue StandardError => e
        { succeed: false, message: e.message }
      end

      # sign up
      def sign_up(name:, email:, password:)
        client.sign_up(
          client_id: client_id,
          username: email,
          password: password,
          user_attributes: [
            {
              name: 'email',
              value: email
            },
            {
              name: 'name',
              value: name
            }
          ]
        )
      rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException
        raise CognitoLoginError, I18n.t('api_errors.cognito.invalid_params')
      rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException
        raise CognitoLoginError, I18n.t('api_errors.cognito.invalid_password')
      end

      # ユーザー一覧
      def admin_user_list
        client.list_users(user_pool_id: user_pool_id).users
      end

      # メール検証
      def confirm_sign_up(email:, confirmation_code:)
        client.confirm_sign_up(
          {
            client_id: client_id,
            username: email,
            confirmation_code: confirmation_code
          }
        )
      rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException
        raise CognitoLoginError, I18n.t('api_errors.cognito.code_mismatch')
      end

      # パスワード忘れた時
      def forgot_password(email:)
        client.forgot_password(
          client_id: client_id,
          username: email,
        )
      rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException
        raise CognitoLoginError, I18n.t('api_errors.cognito.invalid_params')
      end

      # パスワード忘れた時の確認
      def confirm_forgot_password(email:, confirmation_code:, password:)
        client.confirm_forgot_password(
          {
            client_id: client_id,
            username: email,
            confirmation_code: confirmation_code,
            password: password
          }
        )
      rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException
        raise CognitoLoginError, I18n.t('api_errors.cognito.code_mismatch')
      rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException
        raise CognitoLoginError, I18n.t('api_errors.cognito.invalid_password')
      rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
        raise CognitoLoginError, I18n.t('api_errors.cognito.user_not_found')
      end

      # ユーザー有効化
      def admin_enable_user(email:)
        client.admin_enable_user(
          user_pool_id: user_pool_id,
          username: email
        )
      rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
        raise CognitoLoginError, I18n.t('api_errors.cognito.user_not_found')
      end

      # ユーザー無効化
      def admin_disable_user(email:)
        client.admin_disable_user(
          user_pool_id: user_pool_id,
          username: email
        )
      rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
        raise CognitoLoginError, I18n.t('api_errors.cognito.user_not_found')
      end
    end
  end
end
