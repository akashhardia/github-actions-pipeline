# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_areas
#
#  id                  :bigint           not null, primary key
#  displayable         :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  entrance_id         :bigint
#  master_seat_area_id :bigint           not null
#  seat_sale_id        :bigint           not null
#
# Indexes
#
#  index_seat_areas_on_entrance_id          (entrance_id)
#  index_seat_areas_on_master_seat_area_id  (master_seat_area_id)
#  index_seat_areas_on_seat_sale_id         (seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (entrance_id => entrances.id)
#  fk_rails_...  (master_seat_area_id => master_seat_areas.id)
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#
FactoryBot.define do
  factory :seat_area do
    seat_sale
    master_seat_area
    displayable { true }
  end
end
