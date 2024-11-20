# frozen_string_literal: true

# Portalの機能を利用できないユーザーかどうかを判定する
class NgUserChecker
  attr_accessor :user_auth_token

  def initialize(user_auth_token)
    # @user_auth_token = user_auth_token
  end

  def validate!
    # TODO: NGユーザーチェックスキップ　一時的にコメントアウト　specもコメントアウトしているので、「TODO: NGユーザーチェックスキップ」で検索
    # memo taskdo 既存実装でもコメントアウトされており、このチェックは動いていないため、形だけ残して何もしないでおく。
    # raise NgUserError, 'アカウントが無効です' unless validate_sixgram_account && validate_deleted_user
  end

end
