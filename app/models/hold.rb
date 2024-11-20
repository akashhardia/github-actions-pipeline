# frozen_string_literal: true

# == Schema Information
#
# Table name: holds
#
#  id                 :bigint           not null, primary key
#  audience           :boolean
#  first_day          :date             not null
#  first_day_manually :date
#  girl               :boolean
#  grade_code         :string(255)      not null
#  hold_days          :integer          not null
#  hold_name_en       :string(255)
#  hold_name_jp       :string(255)
#  hold_status        :integer
#  period             :integer
#  promoter           :string(255)
#  promoter_code      :string(255)      not null
#  promoter_section   :integer
#  promoter_times     :integer
#  promoter_year      :integer
#  purpose_code       :string(255)      not null
#  repletion_code     :string(255)
#  round              :integer
#  season             :string(255)
#  time_zone          :integer
#  title_en           :string(255)
#  title_jp           :string(255)
#  track_code         :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pf_hold_id         :string(255)      not null
#  tt_movie_yt_id     :string(255)
#
# Indexes
#
#  index_holds_on_hold_status  (hold_status)
#  index_holds_on_pf_hold_id   (pf_hold_id) UNIQUE
#
class Hold < ApplicationRecord
  has_many :hold_dailies, dependent: :destroy
  has_many :hold_daily_schedules, through: :hold_dailies
  has_many :seat_sales, through: :hold_dailies
  has_many :tickets, through: :seat_sales
  has_many :hold_players, dependent: :destroy
  has_many :players, through: :hold_players
  has_many :mediated_players, through: :hold_players
  has_many :races, through: :hold_daily_schedules
  has_many :race_details, through: :races
  has_many :race_result_players, through: :race_details
  has_one :time_trial_result, dependent: :destroy

  scope :filter_hold_with_season, -> do
    where.not(season: nil).where.not(promoter_year: nil).where.not(period: nil)
  end

  scope :filter_hold_with_round, -> do
    where.not(round: nil).where.not(promoter_year: nil).where.not(period: nil)
  end

  scope :current_or_future, -> { where('first_day > ?', Time.zone.today - 2.days) }

  scope :filter_race_result_player_rank, -> do
    where(race_result_players: { rank: 1..100 })
  end

  enum hold_status: {
    before_held: 0, # 開催前
    being_held: 1, # 開催中
    finished_held: 2, # 開催終了
    canceled_in_inspection: 3, # 前検日中止
    canceled_before_inspection: 4, # 前検日前中止
    postponed: 5, # 順延
    medium_postponed: 6, # ４中順延
    discontinuation: 7, # 開催打切
    canceled_full_return: 8, # 開催中止（全返還）
    canceled_takeover: 9 # 開催中止（票数引き継ぎ）
  }

  enum period: Rails.configuration.enum[:period]

  # Validations -----------------------------------------------------------------------------------
  validates :first_day, presence: true
  validates :grade_code, presence: true
  validates :hold_days, presence: true
  validates :promoter_code, presence: true
  validates :purpose_code, presence: true
  validates :track_code, presence: true
  validates :pf_hold_id, presence: true, uniqueness: { case_sensitive: false }
  validates :tt_movie_yt_id, length: { maximum: 255 }

  def mt_hold_status
    canceled_in_inspection? || canceled_before_inspection? ? 2 : 1
  end
end
