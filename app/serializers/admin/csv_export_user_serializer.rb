# frozen_string_literal: true

module Admin
  # 管理画面CSVエクスポート用ユーザーシリアライザー
  class CsvExportUserSerializer < ActiveModel::Serializer
    attributes :id, :sixgram_id, :family_name, :given_name, :family_name_kana, :given_name_kana, :birthday,
               :email, :zip_code, :prefecture, :city, :address_line, :phone_number, :address_detail, :mailmagazine,
               :ng_user_check, :created_at, :deleted_at

    delegate :family_name, :given_name, :family_name_kana, :given_name_kana, :birthday, :email, :zip_code, :prefecture,
             :city, :address_line, :address_detail, :phone_number, :mailmagazine, :ng_user_check, to: :profile

    def deleted_at
      object.deleted_at&.strftime('%Y-%m-%d')
    end

    def created_at
      object.created_at&.strftime('%Y-%m-%d')
    end

    def city
      profile.city&.gsub(',', '_')
    end

    def address_line
      profile.address_line&.gsub(',', '_')
    end

    def address_detail
      profile.address_detail&.gsub(',', '_')
    end

    def email
      profile.email&.gsub(',', '_')
    end

    private

    def profile
      object.profile
    end
  end
end
