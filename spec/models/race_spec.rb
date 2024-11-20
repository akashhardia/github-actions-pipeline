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
require 'rails_helper'

RSpec.describe Race, type: :model do
  describe 'validationの確認' do
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }

    it 'lap_countがなければerrorになること' do
      race = described_class.new(post_start_time: Time.zone.today, program_no: 1, race_code: 1, race_distance: 1, race_no: 1, hold_daily_schedule: hold_daily_schedule)
      expect(race.valid?).to eq false
    end

    it 'post_start_timeがなければerrorになること' do
      race = described_class.new(lap_count: 1, program_no: 1, race_code: 1, race_distance: 1, race_no: 1, hold_daily_schedule: hold_daily_schedule)
      expect(race.valid?).to eq false
    end

    it 'program_noがなければerrorになること' do
      race = described_class.new(lap_count: 1, post_start_time: Time.zone.today, race_code: 1, race_distance: 1, race_no: 1, hold_daily_schedule: hold_daily_schedule)
      expect(race.valid?).to eq false
    end

    it 'race_codeがなければerrorになること' do
      race = described_class.new(lap_count: 1, post_start_time: Time.zone.today, program_no: 1, race_distance: 1, race_no: 1, hold_daily_schedule: hold_daily_schedule)
      expect(race.valid?).to eq false
    end

    it 'race_distanceがなければerrorになること' do
      race = described_class.new(lap_count: 1, post_start_time: Time.zone.today, program_no: 1, race_code: 1, race_no: 1, hold_daily_schedule: hold_daily_schedule)
      expect(race.valid?).to eq false
    end

    it 'race_noがなければerrorになること' do
      race = described_class.new(lap_count: 1, post_start_time: Time.zone.today, program_no: 1, race_code: 1, race_distance: 1, hold_daily_schedule: hold_daily_schedule)
      expect(race.valid?).to eq false
    end

    it 'hold_daily_scheduleがなければerrorになること' do
      race = described_class.new(lap_count: 1, post_start_time: Time.zone.today, program_no: 1, race_code: 1, race_distance: 1, race_no: 1)
      expect(race.valid?).to eq false
    end

    it 'interview_movie_yt_idが256文字以上だったらerrorになること' do
      race = build(:race, interview_movie_yt_id: 'a' * 256)
      expect(race.valid?).to eq false
    end

    it 'interview_movie_yt_idが255文字以内だったらerrorにならないこと' do
      race = build(:race, interview_movie_yt_id: 'a' * 255)
      expect(race.valid?).to eq true
    end

    it 'race_movie_yt_idが256文字以上だったらerrorになること' do
      race = build(:race, race_movie_yt_id: 'a' * 256)
      expect(race.valid?).to eq false
    end

    it 'race_movie_yt_idが255文字以内だったらerrorにならないこと' do
      race = build(:race, race_movie_yt_id: 'a' * 255)
      expect(race.valid?).to eq true
    end
  end

  describe 'クラスメソッドの確認' do
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }
    let(:race) { create(:race, hold_daily_schedule: hold_daily_schedule, free_text: "一行目\n二行目") }
    let(:race2) { create(:race, hold_daily_schedule: hold_daily_schedule, free_text: "一行目\r二行目") }

    it 'formated_free_textのメソッドで改行コードが<br />に置換できることを確認' do
      expect(race.formated_free_text).to eq('一行目<br />二行目')
      expect(race2.formated_free_text).to eq('一行目<br />二行目')
    end
  end
end
