# frozen_string_literal: true

namespace :unsubscribed_user do
  desc '退会ユーザーの情報を削除する'
  task delete_personal_info: :environment do
    # 退会後、11日以上経過しているユーザーを削除対象とする
    target_datetime = Time.zone.now.end_of_day - 11.days
    users = User.where('deleted_at < ?', target_datetime).where.not('sixgram_id LIKE ?', 'unsubscribed_user%')
    UnsubscribedUserHandler.delete_personal_info(users.to_a) if users.present?
  end
end
