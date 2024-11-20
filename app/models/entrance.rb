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
class Entrance < ApplicationRecord
  belongs_to :track
  has_many :seat_areas, dependent: :nullify
  has_many :template_seat_areas, dependent: :nullify
end
