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
require 'rails_helper'

RSpec.describe HoldDaily, type: :model do
  describe 'validationの確認' do
    let(:hold) { create(:hold) }

    it 'daily_branchがなければerrorになること' do
      hold_daily = described_class.new(daily_status: :before_held, event_date: Time.zone.today, hold_daily: 1, hold_id_daily: 1, race_count: 1, hold: hold)
      expect(hold_daily.valid?).to eq false
    end

    it 'daily_statusがなければerrorになること' do
      hold_daily = described_class.new(daily_branch: 1, event_date: Time.zone.today, hold_daily: 1, hold_id_daily: 1, race_count: 1, hold: hold)
      expect(hold_daily.valid?).to eq false
    end

    it 'event_dateがなければerrorになること' do
      hold_daily = described_class.new(daily_branch: 1, daily_status: :before_held, hold_daily: 1, hold_id_daily: 1, race_count: 1, hold: hold)
      expect(hold_daily.valid?).to eq false
    end

    it 'hold_dailyがなければerrorになること' do
      hold_daily = described_class.new(daily_branch: 1, daily_status: :before_held, event_date: Time.zone.today, hold_id_daily: 1, race_count: 1, hold: hold)
      expect(hold_daily.valid?).to eq false
    end

    it 'hold_id_dailyがなければerrorになること' do
      hold_daily = described_class.new(daily_branch: 1, daily_status: :before_held, event_date: Time.zone.today, hold_daily: 1, race_count: 1, hold: hold)
      expect(hold_daily.valid?).to eq false
    end

    it 'race_countがなければerrorになること' do
      hold_daily = described_class.new(daily_branch: 1, daily_status: :before_held, event_date: Time.zone.today, hold_daily: 1, hold_id_daily: 1, hold: hold)
      expect(hold_daily.valid?).to eq false
    end

    it 'holdがなければerrorになること' do
      hold_daily = described_class.new(daily_branch: 1, daily_status: :before_held, event_date: Time.zone.today, hold_daily: 1, race_count: 1, hold_id_daily: 1)
      expect(hold_daily.valid?).to eq false
    end
  end
end
