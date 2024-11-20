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
require 'rails_helper'

RSpec.describe AnnualSchedule, type: :model do
  describe 'validationの確認' do
    it 'activeがなければerrorになること' do
      annual_schedule = described_class.new(active: nil)
      expect(annual_schedule.valid?).to eq false
    end
  end
end
