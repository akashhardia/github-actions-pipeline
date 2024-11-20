# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_areas
#
#  id                    :bigint           not null, primary key
#  displayable           :boolean          default(TRUE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  entrance_id           :bigint
#  master_seat_area_id   :bigint           not null
#  template_seat_sale_id :bigint           not null
#
# Indexes
#
#  index_template_seat_areas_on_entrance_id            (entrance_id)
#  index_template_seat_areas_on_master_seat_area_id    (master_seat_area_id)
#  index_template_seat_areas_on_template_seat_sale_id  (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (entrance_id => entrances.id)
#  fk_rails_...  (master_seat_area_id => master_seat_areas.id)
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
FactoryBot.define do
  factory :template_seat_area do
    master_seat_area
    template_seat_sale
    displayable { true }
    entrance
  end
end
