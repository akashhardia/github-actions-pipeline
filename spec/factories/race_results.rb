# frozen_string_literal: true

# == Schema Information
#
# Table name: race_results
#
#  id             :bigint           not null, primary key
#  bike_count     :integer
#  last_lap       :decimal(6, 4)
#  post_time      :string(255)
#  race_stts      :string(255)
#  race_time      :decimal(6, 4)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  entries_id     :string(255)      not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_race_results_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
FactoryBot.define do
  factory :race_result do
    race_detail
    bike_count { 6 }
    last_lap { 12.3456 }
    post_time { '1100' }
    entries_id { '20200301' }
  end
end
