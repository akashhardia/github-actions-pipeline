# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  deleted_at               :datetime
#  email_auth_code          :string(255)
#  email_auth_expired_at    :datetime
#  email_verified           :boolean          default(FALSE), not null
#  unsubscribe_mail_sent_at :datetime
#  unsubscribe_uuid         :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  qr_user_id               :string(255)
#  sixgram_id               :string(255)      not null
#
# Indexes
#
#  index_users_on_sixgram_id  (sixgram_id) UNIQUE
#
FactoryBot.define do
  factory :user do
    sequence(:sixgram_id)
    qr_user_id { SecureRandom.urlsafe_base64(32) }

    trait :user_with_order do
      after(:create) do |user|
        create(:order, :with_ticket_reserve_in_admission, user: user)
      end
    end

    trait :with_order_to_logs do
      after(:create) do |user|
        create(:order, :within_admission_and_logs, user: user)
      end
    end

    trait :with_ticket_after_event do
      after(:create) do |user|
        create(:ticket, :after_event, user: user, status: :sold)
      end
    end

    trait :with_ticket_today_event do
      after(:create) do |user|
        create(:ticket, :today_event, user: user, status: :sold)
      end
    end

    trait :with_ticket_before_event_one_day do
      after(:create) do |user|
        create(:ticket, :before_event_one_day, user: user, status: :sold)
      end
    end

    trait :with_ticket_before_event_over_one_day do
      after(:create) do |user|
        create(:ticket, :before_event_over_one_day, user: user, status: :sold)
      end
    end

    trait :with_profile do
      after(:create) do |user|
        create(:profile, user: user)
      end
    end
  end
end
