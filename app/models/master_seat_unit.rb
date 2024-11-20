# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_units
#
#  id         :bigint           not null, primary key
#  seat_type  :integer
#  unit_name  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class MasterSeatUnit < ApplicationRecord
  has_many :master_seats, dependent: :nullify
  has_many :tickets, dependent: :nullify

  enum seat_type: {
    box: 0, # 通常のBOX販売
    vip: 1 # VIP席
  }
end
