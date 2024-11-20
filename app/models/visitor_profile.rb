# frozen_string_literal: true

# == Schema Information
#
# Table name: visitor_profiles
#
#  id               :bigint           not null, primary key
#  address_detail   :string(255)
#  address_line     :string(255)
#  birthday         :date             not null
#  city             :string(255)
#  email            :string(255)      not null
#  family_name      :string(255)      not null
#  family_name_kana :string(255)      not null
#  given_name       :string(255)      not null
#  given_name_kana  :string(255)      not null
#  prefecture       :string(255)
#  zip_code         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  sixgram_id       :string(255)      not null
#  ticket_id        :bigint           not null
#
# Indexes
#
#  index_visitor_profiles_on_ticket_id  (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (ticket_id => tickets.id)
#
class VisitorProfile < ApplicationRecord
  belongs_to :ticket

  # Validations -----------------------------------------------------------------------------------
  # バリデーションについてはprofileのバリデーションが変更される可能性があるのでpresenceのみ設定
  validates :family_name, presence: true
  validates :given_name, presence: true
  validates :family_name_kana, presence: true
  validates :given_name_kana, presence: true
  validates :birthday, presence: true
  validates :email, presence: true
  validates :sixgram_id, presence: true
end
