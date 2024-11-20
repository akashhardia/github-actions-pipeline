# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_dailies
#
#  id            :bigint           not null, primary key
#  daily_branch  :integer          not null
#  daily_status  :integer          not null
#  event_date    :date             not null
#  hold_daily    :integer          not null
#  hold_id_daily :integer          not null
#  program_count :integer
#  race_count    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_id       :bigint           not null
#
# Indexes
#
#  index_hold_dailies_on_hold_id  (hold_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#
class HoldDaily < ApplicationRecord
  belongs_to :hold
  has_many :hold_daily_schedules, dependent: :destroy
  has_many :races, through: :hold_daily_schedules
  has_many :seat_sales, through: :hold_daily_schedules
  has_many :coupon_hold_daily_conditions, through: :hold_daily_schedules
  has_many :race_details, through: :races

  delegate :hold_name_jp, :promoter_year, :period, :round, to: :hold

  scope :filter_races_holds, -> do
    where.not(races: { details_code: nil }).where.not(hold: { promoter_year: nil }).where.not(hold: { period: nil }).where.not(hold: { round: nil })
  end

  enum daily_status: Rails.configuration.enum[:daily_status]

  # Validations -----------------------------------------------------------------------------------
  validates :daily_branch, presence: true
  validates :daily_status, presence: true
  validates :event_date, presence: true
  validates :hold_daily, presence: true
  validates :hold_id_daily, presence: true
  validates :race_count, presence: true
  validates :hold_id, presence: true
end
