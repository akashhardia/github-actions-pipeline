# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seats
#
#  id                    :bigint           not null, primary key
#  status                :integer          default("available"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_id        :bigint           not null
#  template_seat_area_id :bigint           not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_template_seats_on_master_seat_id         (master_seat_id)
#  index_template_seats_on_template_seat_area_id  (template_seat_area_id)
#  index_template_seats_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_id => master_seats.id)
#  fk_rails_...  (template_seat_area_id => template_seat_areas.id)
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
FactoryBot.define do
  factory :template_seat do
    master_seat
    template_seat_type
    template_seat_area
    status { :available }
  end
end
