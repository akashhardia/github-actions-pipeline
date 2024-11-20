# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_sale_schedules
#
#  id                       :bigint           not null, primary key
#  admission_available_time :string(255)      not null
#  admission_close_time     :string(255)      not null
#  sales_end_time           :string(255)      not null
#  target_hold_schedule     :integer          not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  template_seat_sale_id    :bigint           not null
#
# Indexes
#
#  index_template_seat_sale_schedules_on_template_seat_sale_id  (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
require 'rails_helper'

RSpec.describe TemplateSeatSaleSchedule, type: :model do
  describe 'validationの確認' do
    it 'admission_available_timeがなければerrorになること' do
      template_seat_sale_schedule = build(:template_seat_sale_schedule, admission_available_time: nil)
      expect(template_seat_sale_schedule.invalid?).to be true
      expect(template_seat_sale_schedule.errors.details[:admission_available_time][0][:error]).to eq(:blank)
    end

    it 'admission_close_timeがなければerrorになること' do
      template_seat_sale_schedule = build(:template_seat_sale_schedule, admission_close_time: nil)
      expect(template_seat_sale_schedule.invalid?).to be true
      expect(template_seat_sale_schedule.errors.details[:admission_close_time][0][:error]).to eq(:blank)
    end

    it 'sales_end_timeがなければerrorになること' do
      template_seat_sale_schedule = build(:template_seat_sale_schedule, sales_end_time: nil)
      expect(template_seat_sale_schedule.invalid?).to be true
      expect(template_seat_sale_schedule.errors.details[:sales_end_time][0][:error]).to eq(:blank)
    end

    it 'target_hold_scheduleがなければerrorになること' do
      template_seat_sale_schedule = build(:template_seat_sale_schedule, target_hold_schedule: nil)
      expect(template_seat_sale_schedule.invalid?).to be true
      expect(template_seat_sale_schedule.errors.details[:target_hold_schedule][0][:error]).to eq(:blank)
    end

    context 'admission_available_time < admission_close_time の場合' do
      let(:template_seat_sale_schedule) { build(:template_seat_sale_schedule, admission_available_time: '16:00', admission_close_time: '16:01') }

      it '正常であること' do
        expect(template_seat_sale_schedule).to be_valid
      end
    end

    context 'admission_close_time ≦ admission_available_time の場合' do
      let(:template_seat_sale_schedule_1) { build(:template_seat_sale_schedule, admission_available_time: '16:00', admission_close_time: '16:00') }
      let(:template_seat_sale_schedule_2) { build(:template_seat_sale_schedule, admission_available_time: '16:01', admission_close_time: '16:00') }

      it 'errorになること' do
        expect(template_seat_sale_schedule_1).not_to be_valid
        expect(template_seat_sale_schedule_2).not_to be_valid
      end
    end

    context 'sales_end_time < admission_close_time の場合' do
      let(:template_seat_sale_schedule) { build(:template_seat_sale_schedule, sales_end_time: '16:00', admission_close_time: '16:01') }

      it '正常であること' do
        expect(template_seat_sale_schedule).to be_valid
      end
    end

    context 'admission_close_time ≦ sales_end_time の場合' do
      let(:template_seat_sale_schedule_1) { build(:template_seat_sale_schedule, admission_close_time: '16:00', sales_end_time: '16:00') }
      let(:template_seat_sale_schedule_2) { build(:template_seat_sale_schedule, admission_close_time: '16:00', sales_end_time: '16:01') }

      it 'errorになること' do
        expect(template_seat_sale_schedule_1).not_to be_valid
        expect(template_seat_sale_schedule_2).not_to be_valid
      end
    end
  end

  describe 'self.target_find_by(hold_daily_schedule)' do
    before do
      4.times { |n| create(:template_seat_sale_schedule, target_hold_schedule: n) }
    end

    context '渡したhold_daily_scheduleが1日目の午前開催の場合' do
      let(:hold_daily) { create(:hold_daily, hold_daily: 1) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily, daily_no: 'am') }

      it '対象のtemplate_seat_sale_scheduleが返ること' do
        template_seat_sale_schedule = described_class.target_find_by(hold_daily_schedule)
        expect(template_seat_sale_schedule).to be_present
        expect(template_seat_sale_schedule.target_hold_schedule).to eq('first_day')
      end
    end

    context '渡したhold_daily_scheduleが1日目の午後開催の場合' do
      let(:hold_daily) { create(:hold_daily, hold_daily: 1) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily, daily_no: 'pm') }

      it '対象のtemplate_seat_sale_scheduleが返ること' do
        template_seat_sale_schedule = described_class.target_find_by(hold_daily_schedule)
        expect(template_seat_sale_schedule).to be_present
        expect(template_seat_sale_schedule.target_hold_schedule).to eq('first_night')
      end
    end

    context '渡したhold_daily_scheduleが2日目の午前開催の場合' do
      let(:hold_daily) { create(:hold_daily, hold_daily: 2) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily, daily_no: 'am') }

      it '対象のtemplate_seat_sale_scheduleが返ること' do
        template_seat_sale_schedule = described_class.target_find_by(hold_daily_schedule)
        expect(template_seat_sale_schedule).to be_present
        expect(template_seat_sale_schedule.target_hold_schedule).to eq('second_day')
      end
    end

    context '渡したhold_daily_scheduleが2日目の午後開催の場合' do
      let(:hold_daily) { create(:hold_daily, hold_daily: 2) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily, daily_no: 'pm') }

      it '対象のtemplate_seat_sale_scheduleが返ること' do
        template_seat_sale_schedule = described_class.target_find_by(hold_daily_schedule)
        expect(template_seat_sale_schedule).to be_present
        expect(template_seat_sale_schedule.target_hold_schedule).to eq('second_night')
      end
    end
  end
end
