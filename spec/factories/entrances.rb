# frozen_string_literal: true

# == Schema Information
#
# Table name: entrances
#
#  id            :bigint           not null, primary key
#  entrance_code :string(255)      not null
#  name          :string(255)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  track_id      :bigint           not null
#
# Indexes
#
#  index_entrances_on_track_id  (track_id)
#
# Foreign Keys
#
#  fk_rails_...  (track_id => tracks.id)
#
FactoryBot.define do
  factory :entrance do
    track
    entrance_code { 'test_code' }
    name { 'エントランスA' }
  end
end
