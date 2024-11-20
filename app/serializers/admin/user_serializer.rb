# frozen_string_literal: true

module Admin
  # 管理画面ユーザーシリアライザー
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :sixgram_id, :email_verified, :family_name, :given_name, :family_name_kana, :given_name_kana, :birthday,
               :email, :zip_code, :prefecture, :city, :address_line, :phone_number, :address_detail, :deleted_at

    delegate :family_name, :given_name, :family_name_kana, :given_name_kana, :birthday, :email, :zip_code, :prefecture, :city, :address_line, :address_detail, :phone_number, to: :profile

    def deleted_at
      object.deleted_at&.strftime('%Y-%m-%d')
    end

    private

    def profile
      object.profile
    end
  end
end
