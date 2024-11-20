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
class RaceResult < ApplicationRecord
  belongs_to :race_detail
  has_many :race_result_players, dependent: :destroy

  validates :entries_id, presence: true
end
