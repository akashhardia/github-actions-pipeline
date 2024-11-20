# frozen_string_literal: true

# == Schema Information
#
# Table name: rear_wheel_infos
#
#  id           :bigint           not null, primary key
#  rental_code  :integer
#  wheel_code   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  bike_info_id :bigint           not null
#
# Indexes
#
#  index_rear_wheel_infos_on_bike_info_id  (bike_info_id)
#
# Foreign Keys
#
#  fk_rails_...  (bike_info_id => bike_infos.id)
#
FactoryBot.define do
  factory :rear_wheel_info do
    bike_info
  end
end
