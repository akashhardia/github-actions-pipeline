# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class MasterSeatType < ApplicationRecord
  has_many :master_seats, dependent: :destroy
  has_many :coupon_seat_type_conditions, dependent: :destroy
  has_many :seat_types, dependent: :destroy
  has_many :campaign_master_seat_types, dependent: :destroy
  has_many :campaigns, through: :campaign_master_seat_types

  # Validations -----------------------------------------------------------------------------------
  validates :name, presence: true
end
