# frozen_string_literal: true

# == Schema Information
#
# Table name: time_trial_rear_wheel_infos
#
#  id                      :bigint           not null, primary key
#  rental_code             :integer
#  wheel_code              :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  time_trial_bike_info_id :bigint           not null
#
# Indexes
#
#  index_time_trial_rear_wheel_infos_on_time_trial_bike_info_id  (time_trial_bike_info_id)
#
# Foreign Keys
#
#  fk_rails_...  (time_trial_bike_info_id => time_trial_bike_infos.id)
#
FactoryBot.define do
  factory :time_trial_rear_wheel_info do
  end
end
