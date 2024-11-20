# frozen_string_literal: true

# == Schema Information
#
# Table name: annual_schedules
#
#  id               :bigint           not null, primary key
#  active           :boolean          default(FALSE), not null
#  audience         :boolean
#  first_day        :date
#  girl             :boolean
#  grade_code       :string(255)
#  hold_days        :integer
#  period           :integer
#  pre_day          :boolean
#  promoter_section :integer
#  promoter_times   :integer
#  promoter_year    :integer
#  round            :integer
#  time_zone        :integer
#  track_code       :string(255)
#  year_name        :string(255)
#  year_name_en     :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pf_id            :string(255)      not null
#
# Indexes
#
#  index_annual_schedules_on_pf_id  (pf_id) UNIQUE
#
class AnnualSchedule < ApplicationRecord
  attr_accessor :event_date

  # MT用スコープ
  scope :mt_api_scope, ->(promoter_year) do
    promoter_year = promoter_year.to_i
    where(promoter_year: promoter_year)
      .or(AnnualSchedule.where(promoter_year: promoter_year - 1).where(first_day: Date.new(promoter_year, 3).all_month))
      .or(AnnualSchedule.where(promoter_year: promoter_year + 1).where(first_day: Date.new(promoter_year + 1, 4).all_month))
      .where.not(first_day: nil)
      .where.not(hold_days: nil)
      .where.not(girl: nil)
      .where.not(audience: nil)
      .where(active: true)
      .order(:first_day)
  end

  enum period: Rails.configuration.enum[:period]

  # Validations -----------------------------------------------------------------------------------
  validates :active, inclusion: { in: [true, false] }
end
