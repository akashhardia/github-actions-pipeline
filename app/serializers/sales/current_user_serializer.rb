# frozen_string_literal: true

module Sales
  # ログインユーザーの情報として渡すもののデフォルトを定義するシリアライザ
  class CurrentUserSerializer < UserSerializer
    attributes :family_name, :given_name

    delegate :family_name, :given_name, to: :profile

    private

    def profile
      Profile.select(:family_name, :given_name).find_by!(user: object)
    end
  end
end
