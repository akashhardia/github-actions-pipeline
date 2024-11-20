# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id               :bigint           not null, primary key
#  address_detail   :string(255)
#  address_line     :string(255)
#  auth_code        :text(65535)
#  birthday         :date             not null
#  city             :string(255)
#  email            :string(255)      not null
#  family_name      :string(255)      not null
#  family_name_kana :string(255)      not null
#  given_name       :string(255)      not null
#  given_name_kana  :string(255)      not null
#  mailmagazine     :boolean          default(FALSE), not null
#  ng_user_check    :boolean          default(TRUE), not null
#  phone_number     :string(255)
#  prefecture       :string(255)
#  zip_code         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Profile < ApplicationRecord
  belongs_to :user

=begin
  validates :family_name, presence: true, length: { maximum: 15 }
  validates :given_name, presence: true, length: { maximum: 15 }
  validates :family_name_kana,
            presence: true, length: { maximum: 30 },
            format: { with: /\A[ァ-ヶー－]+\z/ }
  validates :given_name_kana,
            presence: true, length: { maximum: 30 },
            format: { with: /\A[ァ-ヶー－]+\z/ }
  validates :birthday, presence: true
  validates :email, presence: true, length: { maximum: 256 }, format: { with: /\A\S+@\S+\.\S+\z/ }
  # validates :email_confirmation, presence: true
  validates :zip_code, presence: true,
                       format: { with: /\A[0-9]{7}\z/ }
  validates :prefecture, presence: true
  validates :city, length: { maximum: 100 }, presence: true
  validates :address_line, length: { maximum: 200 }, presence: true
  validates :address_detail, length: { maximum: 200 }
  validates :phone_number, presence: true, length: { maximum: 11 }, format: { with: /\A0\d{2}\d{4}\d{4}\z/ }, allow_blank: true

  before_validation :trim_name

  validate :email_valid?
=end

  def full_name
    "#{family_name} #{given_name}"
  end

  def scoped_serializer(*attributes)
    ActiveModelSerializers::SerializableResource.new(self, fields: attributes)
  end

  private

  def trim_name
    self.family_name = family_name&.gsub(/[[:space:]]/, '')
    self.family_name_kana = family_name_kana&.gsub(/[[:space:]]/, '')
    self.given_name = given_name&.gsub(/[[:space:]]/, '')
    self.given_name_kana = given_name_kana&.gsub(/[[:space:]]/, '')
  end

  def email_valid?
    errors.add(:email, I18n.t('activerecord.errors.models.profile.invalid')) unless email.ascii_only?
  end
end
