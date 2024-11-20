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
FactoryBot.define do
  factory :master_seat_unit do
    seat_type { :box }
  end
end
