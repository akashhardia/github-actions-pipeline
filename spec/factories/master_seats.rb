# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seats
#
#  id                  :bigint           not null, primary key
#  row                 :string(255)
#  sales_type          :integer          not null
#  seat_number         :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  master_seat_area_id :bigint           not null
#  master_seat_type_id :bigint           not null
#  master_seat_unit_id :bigint
#
# Indexes
#
#  index_master_seats_on_master_seat_area_id  (master_seat_area_id)
#  index_master_seats_on_master_seat_type_id  (master_seat_type_id)
#  index_master_seats_on_master_seat_unit_id  (master_seat_unit_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_area_id => master_seat_areas.id)
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (master_seat_unit_id => master_seat_units.id)
#
FactoryBot.define do
  factory :master_seat do
    master_seat_area
    master_seat_type
    row { Faker::Alphanumeric.unique.alpha }
    seat_number { Faker::Number.unique.number(digits: 9) }
    sales_type { :single }
  end
end
