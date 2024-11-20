# frozen_string_literal: true

module NewSystem
  # sixgram api fetcher
  class Api

    BASE_URL = "#{Rails.application.credentials.new_system[:base_url]}"
    REFERER = "#{Rails.application.credentials.new_system[:referer]}"

    class << self
      def post_profile (this_system_user_id ,family_name, given_name, family_kana, given_kana, birthdate, email, zip_code, prefecture, city, address_line, mailmagazine, address_detail, email_confirmation)
        api_path = 'user/name'
        # request_method = "POST&/user_auth/api/#{api_path}"

        # jwt = generate_access_jwt(user_auth_token, request_method)

        body = {
          old_user_id: this_system_user_id,
          family_name: family_name,
          given_name: given_name,
          family_kana: family_kana,
          given_kana: given_kana,
          birthdate: birthdate,
          email: email,
          zip_code: zip_code,
          prefecture: prefecture,
          city: city,
          block: address_line,
          mailmagazine_flg: mailmagazine,
          building: address_detail,
          email_confirmation: email_confirmation,
        }

        headers = {
          "Content-Type": "application/json",
          "Referer": REFERER
        }

        HTTParty.post(BASE_URL + "/api/user/validate", headers: headers, body: body.to_json)
      end

      def validate_profile (this_system_user_id ,family_name, given_name, family_kana, given_kana, birthdate, email, zip_code, prefecture, city, address_line, mailmagazine, address_detail, email_confirmation, email_auth_code)

        body = {
          token: email_auth_code,
          old_user_id: this_system_user_id,
          family_name: family_name,
          given_name: given_name,
          family_kana: family_kana,
          given_kana: given_kana,
          birthdate: birthdate,
          email: email,
          zip_code: zip_code,
          prefecture: prefecture,
          city: city,
          block: address_line,
          mailmagazine_flg: mailmagazine,
          building: address_detail,
          email_confirmation: email_confirmation,
        }

        headers = {
          "Content-Type": "application/json",
          "Referer": REFERER
        }

        HTTParty.post(BASE_URL + "/api/user/validate", headers: headers, body: body.to_json)
      end

      def post_update_profile_token(token)
        headers = {
          "Content-Type": "application/json",
          "Referer": REFERER
        }

        body = {
          token: token
        }

        HTTParty.post(BASE_URL + "/api/user/update", headers: headers, body: body.to_json)
      end

      def charge_status(charge_id)
        body = {
          integration_uuid: charge_id
        }
        # 支払方法(クレカかPayPayかなど)に関わらず同じAPIを叩ける
        api_response = HTTParty.post(BASE_URL + "/api/payment/charge_status", headers: { "Content-Type": "application/json", "Referer": REFERER },  body: body.to_json)
        api_response_body = JSON.parse(api_response.body)

        # OKか否かを表すオブジェクトを返す
        {
          **api_response_body,
          response: {
            code: api_response.code
          }
        }
      end

      def refund(charge_id)
        body = {
          integration_uuid: charge_id
        }
        # 支払方法(クレカかPayPayかなど)に関わらず同じAPIを叩ける
        api_response = HTTParty.post(BASE_URL + "/api/payment/refund", headers: { "Content-Type": "application/json", "Referer": REFERER },  body: body.to_json)
        api_response_body = JSON.parse(api_response.body)

        # OKか否かを表すオブジェクトを返す
        { ok?: api_response_body['is_ok'] }
      end
    end
  end
end
