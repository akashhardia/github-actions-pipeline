# frozen_string_literal: true

module NewSystem
  # 新会員基盤 api service
  class Service
    class << self

      # プロフィール登録
      def post_user_profile(this_system_user_id, family_name, given_name, family_kana, given_kana, birthdate, email, zip_code, prefecture, city, address_line, mailmagazine, address_detail, email_confirmation)
        ApiProvider.new_system.post_profile(this_system_user_id, family_name, given_name, family_kana, given_kana, birthdate, email, zip_code, prefecture, city, address_line, mailmagazine, address_detail, email_confirmation)
      end

      def post_update_profile_token(token)
        ApiProvider.new_system.post_update_profile_token(token)
      end

      def validate_user_profile(this_system_user_id, family_name, given_name, family_kana, given_kana, birthdate, email, zip_code, prefecture, city, address_line, mailmagazine, address_detail, email_confirmation, email_auth_code)
        ApiProvider.new_system.validate_profile(this_system_user_id, family_name, given_name, family_kana, given_kana, birthdate, email, zip_code, prefecture, city, address_line, mailmagazine, address_detail, email_confirmation, email_auth_code)
      end

      # charge_idはいわゆるintegration_uuidの値
      def charge_status(charge_id)
        ApiProvider.new_system.charge_status(charge_id)
      end

      def refund(charge_id)
        ApiProvider.new_system.refund(charge_id)
      end
    end
  end
end