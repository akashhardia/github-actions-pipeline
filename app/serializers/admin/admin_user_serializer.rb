# frozen_string_literal: true

module Admin
  # 管理画面管理ユーザーシリアライザー
  class AdminUserSerializer < ActiveModel::Serializer
    attributes :uuid, :name, :email_verified, :email, :enabled, :user_status, :user_create_date, :user_last_modified_date

    delegate :enabled, :user_status, to: :object

    def uuid
      object.username
    end

    def name
      object.attributes.find { |h| h.name == 'name' }&.value
    end

    def email_verified
      object.attributes.find { |h| h.name == 'email_verified' }&.value
    end

    def email
      object.attributes.find { |h| h.name == 'email' }&.value
    end

    def user_create_date
      object.user_create_date.strftime('%Y-%m-%d %H:%M:%S')
    end

    def user_last_modified_date
      object.user_last_modified_date.strftime('%Y-%m-%d %H:%M:%S')
    end
  end
end
