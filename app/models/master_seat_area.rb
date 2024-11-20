# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_areas
#
#  id           :bigint           not null, primary key
#  area_code    :string(255)      not null
#  area_name    :string(255)      not null
#  position     :string(255)
#  sub_code     :string(255)
#  sub_position :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class MasterSeatArea < ApplicationRecord
  has_many :master_seats, dependent: :destroy
  has_many :seat_areas, dependent: :destroy

  # Validations -----------------------------------------------------------------------------------
  validates :area_code, presence: true
  validates :area_name, presence: true
end
