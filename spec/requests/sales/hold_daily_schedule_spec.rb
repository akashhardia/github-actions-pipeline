# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sales::HoldDailySchedule', type: :request do
  let(:available_seat_sales) { create_list(:seat_sale, 2, :available) }
  let(:unsale_seat_sale) { create(:seat_sale) }
  let(:out_of_term_seat_sale) { create(:seat_sale, :out_of_term, sales_status: 'on_sale') }
  let(:seat_type) { create(:seat_type, :available_for_sale) }
  let(:not_for_sale_ticket) { create(:ticket, :not_for_sale, seat_type_id: seat_type.id) }

  describe 'GET /sales/hold_daily_schedule', :sales_logged_in do
    subject(:hold_daily_schedule_index) { get sales_hold_daily_schedules_url(format: :json) }

    it 'HTTPステータスが200であること' do
      available_seat_sales
      unsale_seat_sale
      hold_daily_schedule_index
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは ["id", "period", "promoterYear", "round", "holdDailies"] の属性を持つハッシュであること' do
      available_seat_sales
      unsale_seat_sale
      hold_daily_schedule_index
      json = JSON.parse(response.body)
      json.all? { |hash| expect(hash.keys).to match_array(%w[id period promoterYear round holdDailies]) }
    end

    it '販売承認済みであること' do
      available_seat_sales
      unsale_seat_sale
      hold_daily_schedule_index
      json = JSON.parse(response.body)
      expect(json.size).to eq 2
      expect(json.first['holdDailies'].first['holdDailySchedules'].first['salesStatus']).to eq 'on_sale'
    end

    it '販売期間内であること' do
      available_seat_sales
      out_of_term_seat_sale
      hold_daily_schedule_index
      json = JSON.parse(response.body)
      expect(json.size).to eq 2
      first_hold_daily_schedule_id = json.first['holdDailies'].first['holdDailySchedules'].first['id']
      second_hold_daily_schedule_id = json.second['holdDailies'].first['holdDailySchedules'].first['id']
      expect(HoldDailySchedule.find(first_hold_daily_schedule_id).available_seat_sale.available?).to eq true
      expect(HoldDailySchedule.find(second_hold_daily_schedule_id).available_seat_sale.available?).to eq true
    end

    context '販売可能なチケットがある場合' do
      let(:available_ticket) { create(:ticket, seat_type_id: seat_type.id) }

      it 'in_stockフラグがtrueであること' do
        available_ticket
        not_for_sale_ticket
        hold_daily_schedule_index
        json = JSON.parse(response.body)
        expect(json.size).to eq 1
        expect(json.first['holdDailies'].first['holdDailySchedules'].first['inStock']).to eq true
      end
    end

    context 'チケットが売り切れな場合' do
      it 'in_stockフラグがfalseであること' do
        not_for_sale_ticket
        hold_daily_schedule_index
        json = JSON.parse(response.body)
        expect(json.size).to eq 1
        expect(json.first['holdDailies'].first['holdDailySchedules'].first['inStock']).to eq false
      end
    end

    context '複数の販売中である開催情報がある場合' do
      let(:late_hold) { create(:hold, promoter_year: '2020', period: 3, round: 5, first_day: Time.zone.parse('20201024')) }
      let(:early_hold) { create(:hold, promoter_year: '2020', period: 3, round: 5, first_day: Time.zone.parse('20201017')) }

      let(:late_hold_daily_1) { create(:hold_daily, hold: late_hold, event_date: Time.zone.parse('20201024')) }
      let(:late_hold_daily_2) { create(:hold_daily, hold: late_hold, event_date: Time.zone.parse('20201025')) }
      let(:early_hold_daily_1)  { create(:hold_daily, hold: early_hold, event_date: Time.zone.parse('20201017')) }
      let(:early_hold_daily_2)  { create(:hold_daily, hold: early_hold, event_date: Time.zone.parse('20201018')) }

      let(:late_hold_daily_1_hold_daily_schedule_pm) { create(:hold_daily_schedule, hold_daily: late_hold_daily_1, daily_no: 1) }
      let(:late_hold_daily_1_hold_daily_schedule_am) { create(:hold_daily_schedule, hold_daily: late_hold_daily_1, daily_no: 0) }
      let(:late_hold_daily_2_hold_daily_schedule_pm) { create(:hold_daily_schedule, hold_daily: late_hold_daily_2, daily_no: 1) }
      let(:late_hold_daily_2_hold_daily_schedule_am) { create(:hold_daily_schedule, hold_daily: late_hold_daily_2, daily_no: 0) }
      let(:early_hold_daily_1_hold_daily_schedule_pm) { create(:hold_daily_schedule, hold_daily: early_hold_daily_1, daily_no: 1) }
      let(:early_hold_daily_1_hold_daily_schedule_am) { create(:hold_daily_schedule, hold_daily: early_hold_daily_1, daily_no: 0) }
      let(:early_hold_daily_2_hold_daily_schedule_pm) { create(:hold_daily_schedule, hold_daily: early_hold_daily_2, daily_no: 1) }
      let(:early_hold_daily_2_hold_daily_schedule_am) { create(:hold_daily_schedule, hold_daily: early_hold_daily_2, daily_no: 0) }

      before do
        create(:seat_sale, :available, hold_daily_schedule:  late_hold_daily_1_hold_daily_schedule_pm)
        create(:seat_sale, :available, hold_daily_schedule:  late_hold_daily_1_hold_daily_schedule_am)
        create(:seat_sale, :available, hold_daily_schedule:  late_hold_daily_2_hold_daily_schedule_pm)
        create(:seat_sale, :available, hold_daily_schedule:  late_hold_daily_2_hold_daily_schedule_am)
        create(:seat_sale, :available, hold_daily_schedule:  early_hold_daily_1_hold_daily_schedule_pm)
        create(:seat_sale, :available, hold_daily_schedule:  early_hold_daily_1_hold_daily_schedule_am)
        create(:seat_sale, :available, hold_daily_schedule:  early_hold_daily_2_hold_daily_schedule_pm)
        create(:seat_sale, :available, hold_daily_schedule:  early_hold_daily_2_hold_daily_schedule_am)
      end

      it 'httpレスポンスがok' do
        hold_daily_schedule_index
        expect(response).to have_http_status(:ok)
      end

      it 'holdをhold_dailiesのeventDate順でソートして返す' do
        hold_daily_schedule_index
        json = JSON.parse(response.body)
        expect(json[0]['holdDailies'][0]['eventDate']).to be < json[1]['holdDailies'][0]['eventDate']
      end

      it 'hold_dailiesをeventDate順でソートして返す' do
        hold_daily_schedule_index
        json = JSON.parse(response.body)
        expect(json[0]['holdDailies'][0]['eventDate']).to be < json[0]['holdDailies'][1]['eventDate']
      end

      it 'holdDailySchedulesをdaily_no順でソートして返す' do
        hold_daily_schedule_index
        json = JSON.parse(response.body)
        expect(json[0]['holdDailies'][0]['holdDailySchedules'][0]['dailyNo']).to eq('am')
        expect(json[0]['holdDailies'][0]['holdDailySchedules'][1]['dailyNo']).to eq('pm')
      end
    end
  end

  describe 'GET /sales/area_sales_info', :sales_logged_in do
    subject(:area_sales_info) { get sales_area_sales_info_url(seat_sale.hold_daily_schedule.id, format: :json) }

    let(:seat_sale) { create(:seat_sale, :available) }

    let(:master_seat_area_a) { create(:master_seat_area, area_name: 'A', position: 'メイン左側', area_code: 'A') }
    let(:master_seat_area_b) { create(:master_seat_area, area_name: 'B', position: 'メイン左側', area_code: 'B') }
    let(:master_seat_area_c) { create(:master_seat_area, area_name: 'C', position: 'メイン左側', area_code: 'C') }
    let(:master_seat_area_d) { create(:master_seat_area, area_name: 'D', position: 'メイン左側', area_code: 'D') }
    let(:master_seat_area_v) { create(:master_seat_area, area_name: 'VIPルーム', position: nil, area_code: 'V') }
    let(:master_seat_area_u) { create(:master_seat_area, area_name: 'BOXシート', position: nil, area_code: 'U') }

    let(:template_seat_type_high) { create(:template_seat_type, price: 10_000) }
    let(:template_seat_type_low) { create(:template_seat_type, price: 5000) }

    let(:master_seat_type_v_high) { create(:master_seat_type, name: 'vip-test-high') }
    let(:master_seat_type_v_low) { create(:master_seat_type, name: 'vip-test-low') }
    let(:master_seat_type_u_high) { create(:master_seat_type, name: 'box-test-high') }
    let(:master_seat_type_u_low) { create(:master_seat_type, name: 'box-test-low') }

    let(:seat_type_high) { create(:seat_type, template_seat_type: template_seat_type_high, seat_sale: seat_sale) }
    let(:seat_type_low) { create(:seat_type, template_seat_type: template_seat_type_low, seat_sale: seat_sale) }
    let(:seat_type_v_high) { create(:seat_type, template_seat_type: template_seat_type_high, seat_sale: seat_sale, master_seat_type: master_seat_type_v_high) }
    let(:seat_type_v_low) { create(:seat_type, template_seat_type: template_seat_type_low, seat_sale: seat_sale, master_seat_type: master_seat_type_v_low) }
    let(:seat_type_u_high) { create(:seat_type, template_seat_type: template_seat_type_high, seat_sale: seat_sale, master_seat_type: master_seat_type_u_high) }
    let(:seat_type_u_low) { create(:seat_type, template_seat_type: template_seat_type_low, seat_sale: seat_sale, master_seat_type: master_seat_type_u_low) }

    let(:seat_area_a) { create(:seat_area, master_seat_area: master_seat_area_a, seat_sale: seat_sale) }
    let(:seat_area_b) { create(:seat_area, master_seat_area: master_seat_area_b, seat_sale: seat_sale, displayable: false) }
    let(:seat_area_c) { create(:seat_area, master_seat_area: master_seat_area_c, seat_sale: seat_sale) }
    let(:seat_area_d) { create(:seat_area, master_seat_area: master_seat_area_d, seat_sale: seat_sale) }
    let(:seat_area_v) { create(:seat_area, master_seat_area: master_seat_area_v, seat_sale: seat_sale) }
    let(:seat_area_u) { create(:seat_area, master_seat_area: master_seat_area_u, seat_sale: seat_sale, displayable: false) }

    before do
      create(:ticket, seat_type: seat_type_high, seat_area: seat_area_a)
      create(:ticket, seat_type: seat_type_low, seat_area: seat_area_a)
      create(:ticket, seat_type: seat_type_high, seat_area: seat_area_b)
      create(:ticket, seat_type: seat_type_low, status: :sold, seat_area: seat_area_b)
      create(:ticket, seat_type: seat_type_high, status: :not_for_sale, seat_area: seat_area_c)
      create(:ticket, seat_type: seat_type_low, seat_area: seat_area_c)
      create(:ticket, seat_type: seat_type_high, status: :sold, seat_area: seat_area_d)
      create(:ticket, seat_type: seat_type_low, status: :not_for_sale, seat_area: seat_area_d)
      create(:ticket, seat_type: seat_type_v_high, seat_area: seat_area_v)
      create(:ticket, seat_type: seat_type_v_low, seat_area: seat_area_v)
      create(:ticket, seat_type: seat_type_u_high, seat_area: seat_area_u)
      create(:ticket, seat_type: seat_type_u_low, status: :sold, seat_area: seat_area_u)
    end

    it 'HTTPステータスが200であること' do
      area_sales_info
      expect(response).to have_http_status(:ok)
    end

    # ticket：A、販売中、10000円
    # ticket：A、販売中、5000円
    # ticket：B、販売中、10000円
    # ticket：B、売り切れ、5000円
    # ticket：C、販売停止、10000円
    # ticket：C、販売中、5000円
    # ticket：D、売り切れ、10000円
    # ticket：D、販売停止、5000円
    # ticket：V、販売中、10000円
    # ticket：V、販売中、5000円
    # ticket：U、販売中、10000円
    # ticket：U、販売停止、5000円
    it 'jsonは想定通りの形が返ってくることであること' do
      area_sales_info
      json = JSON.parse(response.body)
      expect(json['areas'].first['areaName']).to eq('A')
      expect(json['areas'].first['minPrice']).to eq(5000)
      expect(json['areas'].first['availableSale']).to be_truthy
      expect(json['areas'].first['positionTxt']).to eq('メイン左側')
      expect(json['areas'].first['display']).to be_truthy
      expect(json['areas'].first['areaCode']).to eq('A')
      expect(json['areas'].first['seatTypePriceList']).to eq([{ 'price' => 10000, 'seatTypeName' => 'MyString' }, { 'price' => 5000, 'seatTypeName' => 'MyString' }])
      expect(json['areas'].second['areaName']).to eq('B')
      expect(json['areas'].second['minPrice']).to eq(10_000)
      expect(json['areas'].second['availableSale']).to be_truthy
      expect(json['areas'].second['positionTxt']).to eq('メイン左側')
      expect(json['areas'].second['display']).to be_falsey
      expect(json['areas'].second['areaCode']).to eq('B')
      expect(json['areas'].second['seatTypePriceList']).to eq([{ 'price' => 10000, 'seatTypeName' => 'MyString' }])
      expect(json['areas'].third['areaName']).to eq('C')
      expect(json['areas'].third['minPrice']).to eq(5000)
      expect(json['areas'].third['availableSale']).to be_truthy
      expect(json['areas'].third['positionTxt']).to eq('メイン左側')
      expect(json['areas'].third['areaCode']).to eq('C')
      expect(json['areas'].third['seatTypePriceList']).to eq([{ 'price' => 5000, 'seatTypeName' => 'MyString' }])
      expect(json['holdDailySchedule']['dailyStatus']).to eq('being_held')

      expect(json['areas'][4]['areaName']).to eq('VIPルーム')
      expect(json['areas'][4]['minPrice']).to eq(5000)
      expect(json['areas'][4]['availableSale']).to be_truthy
      expect(json['areas'][4]['positionTxt']).to eq(nil)
      expect(json['areas'][4]['areaCode']).to eq('V')
      expect(json['areas'][4]['seatTypePriceList']).to eq([{ 'price' => 10000, 'seatTypeName' => 'vip-test-high' }, { 'price' => 5000, 'seatTypeName' => 'vip-test-low' }])

      expect(json['areas'][5]['areaName']).to eq('BOXシート')
      expect(json['areas'][5]['minPrice']).to eq(10000)
      expect(json['areas'][5]['availableSale']).to be_truthy
      expect(json['areas'][5]['positionTxt']).to eq(nil)
      expect(json['areas'][5]['areaCode']).to eq('U')
      expect(json['areas'][5]['display']).to be_falsey
      expect(json['areas'][5]['seatTypePriceList']).to eq([{ 'price' => 10000, 'seatTypeName' => 'box-test-high' }])
    end
  end
end
