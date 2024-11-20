# frozen_string_literal: true

# 退会ユーザーの個人情報を削除する
class UnsubscribedUserHandler
  class << self
    def delete_personal_info(unsubscribed_users)
      unsubscribed_users.delete_if { |user| assign_sixgram_id(user) && !user.unsubscribed? }

      ActiveRecord::Base.transaction do
        User.import! unsubscribed_users, on_duplicate_key_update: [:sixgram_id]
        Profile.where(user_id: unsubscribed_users.pluck(:id)).update_all(profile_attributes)
      end
    end

    private

    def assign_sixgram_id(user)
      user.sixgram_id = "unsubscribed_user_#{user.id}_#{user.sixgram_id}"
    end

    def profile_attributes
      {
        family_name: '退会済み',
        given_name: 'ユーザー',
        family_name_kana: 'タイカイズミ',
        given_name_kana: 'ユーザー',
        birthday: '10000101',
        email: 'unsubscribed_user@example.com',
        zip_code: '0000000',
        prefecture: '退会',
        city: '退会',
        address_line: '退会',
        phone_number: nil,
        address_detail: nil,
        auth_code: nil,
        mailmagazine: false
      }
    end
  end
end
