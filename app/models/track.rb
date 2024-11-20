# frozen_string_literal: true

# == Schema Information
#
# Table name: tracks
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  track_code :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Track < ApplicationRecord
  has_many :entrances, dependent: :destroy
  has_many :seat_areas, through: :entrance
  has_many :template_seat_areas, through: :entrance
end
