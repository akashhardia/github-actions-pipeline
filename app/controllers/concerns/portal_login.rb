# frozen_string_literal: true

# ログイン周りのモジュール
module PortalLogin
  extend ActiveSupport::Concern

  def require_login!
    raise LoginRequiredError, I18n.t('custom_errors.messages.login_required_error') if current_user.blank?
  end

  def current_user
    return @current_user if @current_user

    # taskdo memo this_system_user_idがない場合、未ログインであるため、中断する。
    # 戻り値はnilになってしまうが、そもそも未ログインの場合は他のcontrollerの処理でcurrent_userを使うところまで来ないため、NPEで落ちることはない。
    if session[:this_system_user_id].blank?
      return
    end

    return @current_user = User.find(session[:this_system_user_id])
  end

  private

  # ログイン検証に必要な値をセッションに保持
  def add_secure_session
    session[:code_verifire] ||= LoginRequiredUuid.generate_uuid
    # session[:code_state] ||= LoginRequiredUuid.generate_uuid
    # session[:code_nonce] ||= LoginRequiredUuid.generate_uuid
  end

  # ログイン検証に必要な値をセッションから削除
  def delete_secure_session
    session[:code_verifire] = nil
    # session[:code_state] = nil
    # session[:code_nonce] = nil
  end
end
