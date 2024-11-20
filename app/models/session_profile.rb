# frozen_string_literal: true

# 座席選択state管理、座席一時キープ、合計金額の計算など
class SessionProfile
  include Redis::Objects

  # とりあえず15分 要件次第で変更
  PROFILE_EXPIRATION = 15.minutes.freeze

  attr_reader :user_auth_token

  value :profiles, marshal: true, expiration: PROFILE_EXPIRATION

  def initialize(user_auth_token)
    @user_auth_token = user_auth_token
  end

  def id
    # MIXI Mが廃止になるので、代わりにダミーとして入れているの250-portalのユーザーIDを入れる
    "SessionProfile sixgram_id: #{@user_auth_token}"
  end

  # setter
  def attributes=(profile_params)
    profiles.value = profile_params
  end

  # getter
  def attributes
    user_input = profiles.value || {}
    user_input
  end

  def post_personal_data(this_system_user_id)
    # 誕生日を編集するか不明なため一旦コメントアウト
    # birthdate = Time.zone.parse(attributes['birthday']).strftime('%Y%m%d')

    NewSystem::Service.post_user_profile(
      this_system_user_id,
      attributes['family_name'],
      attributes['given_name'],
      attributes['family_name_kana'],
      attributes['given_name_kana'],
      nil, # birthdate,
      attributes['email'],
      attributes['zip_code'],
      attributes['prefecture'],
      attributes['city'],
      attributes['address_line'],
      attributes['mailmagazine'],
      attributes['address_detail'],
      attributes['email_confirmation']
    )
  end

  def validate_personal_data(this_system_user_id, email_auth_code)
    NewSystem::Service.validate_user_profile(
      this_system_user_id,
      attributes['family_name'],
      attributes['given_name'],
      attributes['family_name_kana'],
      attributes['given_name_kana'],
      nil, # birthdate,
      attributes['email'],
      attributes['zip_code'],
      attributes['prefecture'],
      attributes['city'],
      attributes['address_line'],
      attributes['mailmagazine'],
      attributes['address_detail'],
      attributes['email_confirmation'],
      email_auth_code
    )
  end
end
