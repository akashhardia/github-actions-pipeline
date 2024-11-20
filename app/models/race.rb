# frozen_string_literal: true

# == Schema Information
#
# Table name: races
#
#  id                     :bigint           not null, primary key
#  details_code           :string(255)
#  entry_code             :string(255)
#  event_code             :string(255)
#  first_race_code        :string(255)
#  free_text              :text(65535)
#  lap_count              :integer          not null
#  pattern_code           :string(255)
#  post_start_time        :datetime         not null
#  post_time              :string(255)
#  program_no             :integer          not null
#  race_code              :string(255)      not null
#  race_distance          :integer          not null
#  race_no                :integer          not null
#  time_zone_code         :integer
#  type_code              :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  entries_id             :string(255)
#  hold_daily_schedule_id :bigint           not null
#  interview_movie_yt_id  :string(255)
#  race_movie_yt_id       :string(255)
#
# Indexes
#
#  index_races_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#
class Race < ApplicationRecord
  belongs_to :hold_daily_schedule
  has_one :race_detail, dependent: :destroy

  # Validations -----------------------------------------------------------------------------------
  validates :lap_count, presence: true
  validates :post_start_time, presence: true
  validates :program_no, presence: true
  validates :race_code, presence: true
  validates :race_distance, presence: true
  validates :race_no, presence: true
  validates :interview_movie_yt_id, length: { maximum: 255 }
  validates :race_movie_yt_id, length: { maximum: 255 }

  scope :filter_race_result_player_rank, -> do
    where(race_result_players: { rank: 1..100 })
  end

  def formated_free_text
    free_text&.gsub(/[\r\n]/, '<br />')
  end
end
