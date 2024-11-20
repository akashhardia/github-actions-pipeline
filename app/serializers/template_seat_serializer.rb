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
class TemplateSeatSerializer < ApplicationSerializer
  attributes :id, :status, :row, :seat_number, :sales_type, :master_seat_unit_id, :unit_type, :unit_name

  def unit_type
    master_seat_unit&.seat_type
  end

  def unit_name
    master_seat_unit&.unit_name
  end

  private

  def master_seat_unit
    @master_seat_unit ||= object.master_seat.master_seat_unit
  end
end
