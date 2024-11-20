# frozen_string_literal: true

# == Schema Information
#
# Table name: race_details
#
#  id              :bigint           not null, primary key
#  bike_count      :string(255)
#  close_time      :datetime
#  daily_branch    :integer
#  details_code    :string(255)
#  entry_code      :string(255)
#  event_code      :string(255)
#  first_day       :date
#  first_race_code :string(255)
#  grade_code      :string(255)
#  hold_daily      :integer
#  hold_day        :string(255)
#  hold_id_daily   :integer          not null
#  laps_count      :integer
#  pattern_code    :string(255)
#  post_time       :string(255)
#  race_code       :string(255)
#  race_distance   :integer
#  race_status     :string(255)
#  repletion_code  :string(255)
#  time_zone_code  :integer
#  track_code      :string(255)
#  type_code       :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  entries_id      :string(255)      not null
#  pf_hold_id      :string(255)      not null
#  race_id         :bigint           not null
#
# Indexes
#
#  index_race_details_on_race_id  (race_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_id => races.id)
#
require 'rails_helper'

RSpec.describe RaceDetail, type: :model do
  describe 'バリデーション: 必須チェック' do
    it 'pf_hold_idが必須チェックでエラーになること' do
      race_detail = build(:race_detail)
      race_detail.pf_hold_id = nil
      expect(race_detail.invalid?).to be true
      expect(race_detail.errors.details[:pf_hold_id][0][:error]).to eq(:blank)
    end

    it 'hold_id_dailyが必須チェックでエラーになること' do
      race_detail = build(:race_detail)
      race_detail.hold_id_daily = nil
      expect(race_detail.invalid?).to be true
      expect(race_detail.errors.details[:hold_id_daily][0][:error]).to eq(:blank)
    end

    it 'entries_idが必須チェックでエラーになること' do
      race_detail = build(:race_detail)
      race_detail.entries_id = nil
      expect(race_detail.invalid?).to be true
      expect(race_detail.errors.details[:entries_id][0][:error]).to eq(:blank)
    end
  end
end
