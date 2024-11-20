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
class ProfileSerializer < ActiveModel::Serializer
  attributes :id, :family_name, :family_name_kana, :given_name, :given_name_kana,
             :birthday, :email, :zip_code, :prefecture, :city, :address_line, :full_name, :mailmagazine, :phone_number, :created_at,
             :last_purchase_date, :address_detail

  def birthday
    export_csv ? date_format(object.birthday) : object.birthday
  end

  def created_at
    date_format(object.created_at)
  end

  def last_purchase_date
    last_purchase_date = Order.where(user_id: object.user_id).order(order_at: :desc).limit(1)
    return nil if last_purchase_date[0].blank?

    date_format(last_purchase_date[0].order_at)
  end

  def export_csv
    @instance_options[:action] == :export_csv
  end

  def date_format(date)
    date.strftime('%m/%d/%Y')
  end
end
