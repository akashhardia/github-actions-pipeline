# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_daily_schedules
#
#  id            :bigint           not null, primary key
#  daily_no      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_daily_id :bigint           not null
#
# Indexes
#
#  index_hold_daily_schedules_on_hold_daily_id  (hold_daily_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_id => hold_dailies.id)
#
require 'rails_helper'

RSpec.describe HoldDailySchedule, type: :model do
  describe 'validationの確認' do
    it 'daily_branchがなければerrorになること' do
      hold_daily_schedule = create(:hold_daily_schedule)
      hold_daily_schedule.daily_no = nil
      expect(hold_daily_schedule.valid?).to eq false
      expect(hold_daily_schedule.errors.details[:daily_no][0][:error]).to eq(:blank)
    end
  end

  describe '開催デイリースケジュール毎にチケットが購入可能かの確認' do
    let(:seat_sale) { create(:seat_sale, sales_status: :on_sale) }
    let(:seat_sale_2) { create(:seat_sale, sales_status: 0) }
    let(:user) { create(:user) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }

    describe '#available?' do
      subject(:hold_daily_schedule_available?) { seat_sale.hold_daily_schedule.available? }

      context '販売承認済み / 販売期間内の場合' do
        let(:seat_sale) { create(:seat_sale, :in_term, sales_status: :on_sale) }

        it 'trueであること' do
          expect(hold_daily_schedule_available?).to be true
        end
      end

      context '販売未承認 / 販売期間内の場合' do
        let(:seat_sale) { create(:seat_sale, :in_term, sales_status: :before_sale) }

        it 'falseであること' do
          expect(hold_daily_schedule_available?).to be false
        end
      end

      context '販売承認済み / 販売期間外の場合' do
        let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: :on_sale) }

        it 'falseであること' do
          expect(hold_daily_schedule_available?).to be false
        end
      end
    end
  end

  describe '#can_create_coupon?' do
    subject(:hold_daily_schedule_can_create_coupon?) { seat_sale.hold_daily_schedule.can_create_coupon? }

    context '販売承認済み / 販売終了日前の場合' do
      let(:seat_sale) { create(:seat_sale, :in_term, sales_status: :on_sale) }

      it 'trueであること' do
        expect(hold_daily_schedule_can_create_coupon?).to be true
      end
    end

    context '販売未承認 / 販売終了日前の場合' do
      let(:seat_sale) { create(:seat_sale, :in_term, sales_status: :before_sale) }

      it 'trueであること' do
        expect(hold_daily_schedule_can_create_coupon?).to be true
      end
    end

    context '販売中止 / 販売終了日前の場合' do
      let(:seat_sale) { create(:seat_sale, :in_term, sales_status: :discontinued) }

      it 'falseであること' do
        expect(hold_daily_schedule_can_create_coupon?).to be false
      end
    end

    context '販売承認済み / 販売終了日後の場合' do
      let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: :on_sale) }

      it 'falseであること' do
        expect(hold_daily_schedule_can_create_coupon?).to be false
      end
    end

    context '販売未承認 / 販売終了日後の場合' do
      let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: :before_sale) }

      it 'falseであること' do
        expect(hold_daily_schedule_can_create_coupon?).to be false
      end
    end
  end

  describe 'discontinued以外のseat_saleを取得' do
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }

    describe '#available_seat_sale' do
      subject(:hold_daily_schedule_available_seat_sale) { hold_daily_schedule.available_seat_sale }

      context 'before_saleのseat_saleがある場合' do
        it 'seat_saleが取得できること' do
          seat_sale = create(:seat_sale, sales_status: :before_sale, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_available_seat_sale).to eq(seat_sale)
        end
      end

      context 'on_saleのseat_saleがある場合' do
        it 'seat_saleが取得できること' do
          seat_sale = create(:seat_sale, sales_status: :on_sale, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_available_seat_sale).to eq(seat_sale)
        end
      end

      context 'discontinuedのみのseat_saleがある場合' do
        it 'seat_saleが取得できないこと' do
          create(:seat_sale, sales_status: :discontinued, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_available_seat_sale).to eq(nil)
        end
      end

      context 'discontinuedとon_saleのseat_saleがある場合' do
        it 'on_saleのseat_saleが取得できること' do
          seat_sale = create(:seat_sale, sales_status: :on_sale, hold_daily_schedule: hold_daily_schedule)
          create(:seat_sale, sales_status: :discontinued, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_available_seat_sale).to eq(seat_sale)
        end
      end
    end
  end

  describe 'discontinued以外のseat_saleを取得し、そのsales_statusを返す' do
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }

    describe '#sales_status' do
      subject(:hold_daily_schedule_sales_status) { hold_daily_schedule.sales_status }

      context 'before_saleのseat_saleがある場合' do
        it 'before_saleが返ること' do
          create(:seat_sale, sales_status: :before_sale, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_sales_status).to eq('before_sale')
        end
      end

      context 'on_saleのseat_saleがある場合' do
        it 'on_saleが返ること' do
          create(:seat_sale, sales_status: :on_sale, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_sales_status).to eq('on_sale')
        end
      end

      context 'discontinuedのみのseat_saleがある場合' do
        it 'uncreatedが返ること' do
          create(:seat_sale, sales_status: :discontinued, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_sales_status).to eq('uncreated')
        end
      end

      context 'discontinuedとon_saleのseat_saleがある場合' do
        it 'on_saleが返ること' do
          create(:seat_sale, sales_status: :on_sale, hold_daily_schedule: hold_daily_schedule)
          create(:seat_sale, sales_status: :discontinued, hold_daily_schedule: hold_daily_schedule)
          expect(hold_daily_schedule_sales_status).to eq('on_sale')
        end
      end
    end
  end

  describe 'day_night_display' do
    context 'daily_noがamの場合' do
      let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

      it 'デイの文字列が返ること' do
        expect(hold_daily_schedule.day_night_display).to eq('デイ')
      end
    end

    context 'daily_noがpmの場合' do
      let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

      it 'ナイトの文字列が返ること' do
        expect(hold_daily_schedule.day_night_display).to eq('ナイト')
      end
    end
  end

  describe 'opening_display' do
    context 'hold.time_zoneが1のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 1) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '11:00の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('11:00')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '16:30の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('16:30')
        end
      end
    end

    context 'hold.time_zoneが2のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 2) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '10:30の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('10:30')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '16:00の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('16:00')
        end
      end
    end

    context 'hold.time_zoneが3のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 3) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '13:30の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('13:30')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '17:50の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('17:50')
        end
      end
    end

    context 'hold.time_zoneが4のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 4) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '12:00の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('12:00')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '16:20の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('16:20')
        end
      end
    end

    context 'hold.time_zoneがnilのとき' do
      before { hold_daily_schedule.hold.update(time_zone: nil) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '11:00の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('11:00')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '16:30の文字列が返ること' do
          expect(hold_daily_schedule.opening_display).to eq('16:30')
        end
      end
    end
  end

  describe 'start_display' do
    context 'hold.time_zoneが1のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 1) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '12:25の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('12:25')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '17:55の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('17:55')
        end
      end
    end

    context 'hold.time_zoneが2のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 2) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '空文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '空文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('')
        end
      end
    end

    context 'hold.time_zoneが3のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 3) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '14:00の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('14:00')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '18:20の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('18:20')
        end
      end
    end

    context 'hold.time_zoneが4のとき' do
      before { hold_daily_schedule.hold.update(time_zone: 4) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '13:00の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('13:00')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '17:20の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('17:20')
        end
      end
    end

    context 'hold.time_zoneがnilのとき' do
      before { hold_daily_schedule.hold.update(time_zone: nil) }

      context 'daily_noがamの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :am) }

        it '12:25の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('12:25')
        end
      end

      context 'daily_noがpmの場合' do
        let(:hold_daily_schedule) { create(:hold_daily_schedule, daily_no: :pm) }

        it '17:55の文字列が返ること' do
          expect(hold_daily_schedule.start_display).to eq('17:55')
        end
      end
    end
  end
end
