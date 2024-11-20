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
require 'rails_helper'

RSpec.describe Hold, type: :model do
  describe 'バリデーション: 必須チェック' do
    it 'pf_hold_idが必須チェックでエラーになること' do
      hold = build(:hold)
      hold.pf_hold_id = nil
      expect(hold.invalid?).to be true
      expect(hold.errors.details[:pf_hold_id][0][:error]).to eq(:blank)
    end
  end

  describe 'バリデーション: 重複チェック' do
    it 'pf_hold_idが重複チェックでエラーになること' do
      hold = create(:hold)
      new_hold = build(:hold)
      new_hold.pf_hold_id = hold.pf_hold_id
      expect(new_hold.invalid?).to be true
      expect(new_hold.errors.details[:pf_hold_id][0][:error]).to eq(:taken)
    end
  end

  describe 'validationの確認' do
    it 'first_dayがなければerrorになること' do
      hold = described_class.new(grade_code: 'A', hold_days: 1, promoter_code: 'code', purpose_code: 'code', track_code: 'code', pf_hold_id: 'hold')
      expect(hold.valid?).to eq false
    end

    it 'grade_codeがなければerrorになること' do
      hold = described_class.new(first_day: Time.zone.today, hold_days: 1, promoter_code: 'code', purpose_code: 'code', track_code: 'code', pf_hold_id: 'hold')
      expect(hold.valid?).to eq false
    end

    it 'hold_daysがなければerrorになること' do
      hold = described_class.new(first_day: Time.zone.today, grade_code: 'A', promoter_code: 'code', purpose_code: 'code', track_code: 'code', pf_hold_id: 'hold')
      expect(hold.valid?).to eq false
    end

    it 'promoter_codeがなければerrorになること' do
      hold = described_class.new(first_day: Time.zone.today, grade_code: 'A', hold_days: 1, purpose_code: 'code', track_code: 'code', pf_hold_id: 'hold')
      expect(hold.valid?).to eq false
    end

    it 'purpose_codeがなければerrorになること' do
      hold = described_class.new(first_day: Time.zone.today, grade_code: 'A', hold_days: 1, promoter_code: 'code', track_code: 'code', pf_hold_id: 'hold')
      expect(hold.valid?).to eq false
    end

    it 'track_codeがなければerrorになること' do
      hold = described_class.new(first_day: Time.zone.today, grade_code: 'A', hold_days: 1, promoter_code: 'code', purpose_code: 'code', pf_hold_id: 'hold')
      expect(hold.valid?).to eq false
    end

    it 'pf_hold_idがなければerrorになること' do
      hold = described_class.new(first_day: Time.zone.today, grade_code: 'A', hold_days: 1, promoter_code: 'code', track_code: 'code', purpose_code: 'code')
      expect(hold.valid?).to eq false
    end

    it 'tt_movie_yt_idが256文字以上だったらerrorになること' do
      hold = build(:hold, tt_movie_yt_id: 'a' * 256)
      expect(hold.valid?).to eq false
    end

    it 'tt_movie_yt_idが255文字以内だったらerrorにならないこと' do
      hold = build(:hold, tt_movie_yt_id: 'a' * 255)
      expect(hold.valid?).to eq true
    end
  end

  describe 'mt_hold_status' do
    subject(:mt_hold_status) { hold.send(:mt_hold_status) }

    context 'hold_statusが3または4の場合' do
      let(:hold) { create(:hold, hold_status: [3, 4].sample) }

      it '2を返すこと' do
        expect(mt_hold_status).to eq(2)
      end
    end

    context 'hold_statusが3または4以外の場合' do
      let(:hold) { create(:hold, hold_status: 0) }

      it '1を返すこと' do
        expect(mt_hold_status).to eq(1)
      end
    end
  end
end
