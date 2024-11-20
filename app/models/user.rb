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
class User < ApplicationRecord
  has_many :tickets, dependent: :nullify
  has_many :orders, dependent: :destroy
  has_many :ticket_reserves, through: :orders
  has_many :user_coupons, dependent: :destroy
  has_many :coupons, through: :user_coupons
  has_one :profile, dependent: :destroy

  # Validations -----------------------------------------------------------------------------------
  validates :sixgram_id, presence: true, uniqueness: { case_sensitive: true }

  def qr_user_id_generate!
    update!(qr_user_id: AdmissionUuid.generate_uuid)
  end

  # 退会処理済みかどうかを判定
  def unsubscribed?
    !!deleted_at
  end
end
