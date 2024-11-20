# frozen_string_literal: true

require 'rails_helper'

def fiscal_year(datetime)
  datetime.month <= 3 ? datetime.year - 1 : datetime.year
end

def time_format(time_text)
  return '' if time_text.blank?

  seconds_str = time_text.slice!(-2, 2)
  format('%<minutes>02d:%<seconds>02d', minutes: time_text, seconds: seconds_str)
end

RSpec.describe 'V1::Mt::Datas', type: :request do
  describe 'GET /promoter_years' do
    let!(:last_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now) - 1, season: 'last_year_promoter_year_title', first_day: Time.zone.now.prev_year(1), period: 'wildcard') }

    before do
      create(:hold, promoter_year: fiscal_year(Time.zone.now) - 1, season: 'last_year_promoter_year_title', first_day: Time.zone.now.prev_day(366), period: 'final')
    end

    context '2日前より未来に対象のholdがある場合' do
      let!(:this_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.next_day(1), period: 'summer') }
      let!(:next_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now) + 1, season: 'next_year_promoter_year_title', first_day: Time.zone.now.next_year(1)) }
      let!(:year_after_next_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now) + 2, season: 'year_after_next_promoter_year_title', first_day: Time.zone.now.next_year(2), period: 'autumn') }

      before do
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(2), period: 'spring')
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.next_day(5), period: 'autumn')
        create(:hold, promoter_year: fiscal_year(Time.zone.now) + 1, season: 'next_year_promoter_year_title', first_day: Time.zone.now.next_year(1), period: 'spring')
      end

      it 'current_**は今年度で2日前以降の最初のholdの開催年度、シーズンが取得されること' do
        get v1_mt_datas_promoter_years_path
        json = JSON.parse(response.body)
        expect(json['data']['current_promoter_year_title']).to eq('this_year_promoter_year_title')
        expect(json['data']['current_promoter_year']).to eq(fiscal_year(Time.zone.now))
        expect(json['data']['current_season']).to eq('summer')
      end

      it 'promoter_year_listは存在する開催年度が年度ごとに1件ずつ取得されること' do
        get v1_mt_datas_promoter_years_path
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year_list'][0]['promoter_year_title']).to eq('last_year_promoter_year_title')
        expect(json['data']['promoter_year_list'][0]['promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['promoter_year_list'][1]['promoter_year_title']).to eq('this_year_promoter_year_title')
        expect(json['data']['promoter_year_list'][1]['promoter_year']).to eq(this_promoter_year_hold.promoter_year)
        expect(json['data']['promoter_year_list'][2]['promoter_year_title']).to eq('next_year_promoter_year_title')
        expect(json['data']['promoter_year_list'][2]['promoter_year']).to eq(next_promoter_year_hold.promoter_year)
        expect(json['data']['promoter_year_list'][3]['promoter_year_title']).to eq('year_after_next_promoter_year_title')
        expect(json['data']['promoter_year_list'][3]['promoter_year']).to eq(year_after_next_promoter_year_hold.promoter_year)
      end
    end

    context '開催初日が3日前の開催が最新で、将来の開催がない場合' do
      before do
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(10), period: 'summer', round: 1)
      end

      let!(:recent_past_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(3), period: 'spring', round: 1) }

      it 'current_**はその開催の開催年度、シーズンが取得されること' do
        get v1_mt_datas_promoter_years_path
        json = JSON.parse(response.body)
        expect(json['data']['current_promoter_year_title']).to eq(recent_past_hold.season)
        expect(json['data']['current_promoter_year']).to eq(recent_past_hold.promoter_year)
        expect(json['data']['current_season']).to eq(recent_past_hold.period)
      end

      it 'promoter_year_listは存在する開催年度が年度ごとに1件ずつ取得されること' do
        get v1_mt_datas_promoter_years_path
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year_list'][0]['promoter_year_title']).to eq(last_promoter_year_hold.season)
        expect(json['data']['promoter_year_list'][0]['promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['promoter_year_list'][1]['promoter_year_title']).to eq(recent_past_hold.season)
        expect(json['data']['promoter_year_list'][1]['promoter_year']).to eq(recent_past_hold.promoter_year)
      end
    end

    context 'promoter_yearがnilのデータがある場合' do
      before do
        create(:hold, promoter_year: nil, season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(30), period: 2)
      end

      it 'promoter_yearがnilではないデータしか取得していないこと' do
        get v1_mt_datas_promoter_years_path
        json = JSON.parse(response.body)
        expect(json['data']['current_promoter_year_title']).to eq(last_promoter_year_hold.season)
        expect(json['data']['current_promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['current_season']).to eq(last_promoter_year_hold.period)
        expect(json['data']['promoter_year_list'][0]['promoter_year_title']).to eq(last_promoter_year_hold.season)
        expect(json['data']['promoter_year_list'][0]['promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['promoter_year_list'][1]).to eq nil
      end
    end

    # context 'seasonがnilのデータがある場合' do
    #   before do
    #     create(:hold, promoter_year: fiscal_year(Time.zone.now), season: nil, first_day: Time.zone.now.prev_day(30), period: 2)
    #   end

    #   it 'seasonがnilではないデータしか取得していないこと' do
    #     get v1_mt_datas_promoter_years_path
    #     json = JSON.parse(response.body)
    #     expect(json['data']['current_promoter_year_title']).to eq('決定戦1')
    #     expect(json['data']['current_promoter_year']).to eq(fiscal_year(Time.zone.now) - 1)
    #     expect(json['data']['current_season']).to eq('wildcard')
    #     expect(json['data']['promoter_year_list'][0]['promoter_year_title']).to eq('決定戦1')
    #     expect(json['data']['promoter_year_list'][0]['promoter_year']).to eq(Time.zone.now.year - 1)
    #     expect(json['data']['promoter_year_list'][1]).to eq nil
    #   end
    # end

    context 'periodがnilのデータがある場合' do
      before do
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: '決定戦2-n', first_day: Time.zone.now.prev_day(30), period: nil)
      end

      it 'periodがnilではないデータのみ取得すること' do
        get v1_mt_datas_promoter_years_path
        json = JSON.parse(response.body)
        expect(json['data']['current_promoter_year_title']).to eq(last_promoter_year_hold.season)
        expect(json['data']['current_promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['current_season']).to eq(last_promoter_year_hold.period)
        expect(json['data']['promoter_year_list'][0]['promoter_year_title']).to eq(last_promoter_year_hold.season)
        expect(json['data']['promoter_year_list'][0]['promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['promoter_year_list'][1]).to eq nil
      end
    end
  end

  describe 'GET /finalists' do
    subject(:get_finalists) { get v1_mt_datas_finalists_url, params: params }

    let!(:final_hold) { create(:hold, promoter_year: 2000, period: 'final', round: 301) }
    let!(:spring_hold) { create(:hold, promoter_year: 2000, period: 'spring', round: 301) }
    let!(:summer_hold) { create(:hold, promoter_year: 2000, period: 'summer', round: 301) }
    let!(:autumn_hold) { create(:hold, promoter_year: 2000, period: 'autumn', round: 301) }
    let!(:winter_hold) { create(:hold, promoter_year: 2000, period: 'winter', round: 301) }

    let!(:final_hold_daily) { create(:hold_daily, :with_final_race, hold: final_hold) }
    let!(:spring_hold_daily) { create(:hold_daily, :with_final_race, hold: spring_hold) }
    let!(:summer_hold_daily) { create(:hold_daily, :with_final_race, hold: summer_hold) }
    let!(:autumn_hold_daily) { create(:hold_daily, :with_final_race, hold: autumn_hold) }
    let!(:winter_hold_daily) { create(:hold_daily, :with_final_race, hold: winter_hold) }

    let!(:current_promoter_year_final_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), period: 'final', round: 301) }
    let!(:current_promoter_year_spring_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), period: 'spring', round: 301) }
    let!(:current_promoter_year_summer_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), period: 'summer', round: 301) }
    let!(:current_promoter_year_autumn_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), period: 'autumn', round: 301) }
    let!(:current_promoter_year_winter_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), period: 'winter', round: 301) }

    let!(:current_promoter_year_final_hold_daily) { create(:hold_daily, :with_final_race, hold: current_promoter_year_final_hold) }
    let!(:current_promoter_year_spring_hold_daily) { create(:hold_daily, :with_final_race, hold: current_promoter_year_spring_hold) }
    let!(:current_promoter_year_summer_hold_daily) { create(:hold_daily, :with_final_race, hold: current_promoter_year_summer_hold) }
    let!(:current_promoter_year_autumn_hold_daily) { create(:hold_daily, :with_final_race, hold: current_promoter_year_autumn_hold) }
    let!(:current_promoter_year_winter_hold_daily) { create(:hold_daily, :with_final_race, hold: current_promoter_year_winter_hold) }

    context 'データがあるpromoter_yearを指定した場合' do
      let(:params) { { promoter_year: 2000 } }

      it 'レスポンスパラメータの確認' do
        final_race_player_pf_player_id = final_hold_daily.race_details.first.race_players.first.pf_player_id
        spring_race_player_pf_player_id = spring_hold_daily.race_details.first.race_players.first.pf_player_id
        summer_race_player_pf_player_id = summer_hold_daily.race_details.first.race_players.first.pf_player_id
        autumn_race_player_pf_player_id = autumn_hold_daily.race_details.first.race_players.first.pf_player_id
        winter_race_player_pf_player_id = winter_hold_daily.race_details.first.race_players.first.pf_player_id

        final_race_player_pf_250_regist_id = Player.find_by(pf_player_id: final_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        spring_race_player_pf_250_regist_id = Player.find_by(pf_player_id: spring_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        summer_race_player_pf_250_regist_id = Player.find_by(pf_player_id: summer_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        autumn_race_player_pf_250_regist_id = Player.find_by(pf_player_id: autumn_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        winter_race_player_pf_250_regist_id = Player.find_by(pf_player_id: winter_race_player_pf_player_id).player_original_info&.pf_250_regist_id

        get_finalists
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(2000)
        expect(json['data']['final']['race_id']).to eq(final_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['final']['date']).to eq(final_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['final']['player_list'][0]).to eq(final_race_player_pf_250_regist_id)
        expect(json['data']['spring']['race_id']).to eq(spring_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['spring']['date']).to eq(spring_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['spring']['player_list'][0]).to eq(spring_race_player_pf_250_regist_id)
        expect(json['data']['summer']['race_id']).to eq(summer_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['summer']['date']).to eq(summer_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['summer']['player_list'][0]).to eq(summer_race_player_pf_250_regist_id)
        expect(json['data']['autumn']['race_id']).to eq(autumn_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['autumn']['date']).to eq(autumn_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['autumn']['player_list'][0]).to eq(autumn_race_player_pf_250_regist_id)
        expect(json['data']['winter']['race_id']).to eq(winter_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['winter']['date']).to eq(winter_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['winter']['player_list'][0]).to eq(winter_race_player_pf_250_regist_id)
      end
    end

    context 'データがないpromoter_yearを指定した場合' do
      let(:params) { { promoter_year: 1900 } }

      it 'nilが返る' do
        get_finalists
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'パラメータを指定しない場合、' do
      let(:params) { nil }

      it 'パラメータを指定しない場合、現在シーズンの情報を取得' do
        current_promoter_year_final_race_player_pf_player_id = current_promoter_year_final_hold_daily.race_details.first.race_players.first.pf_player_id
        current_promoter_year_spring_race_player_pf_player_id = current_promoter_year_spring_hold_daily.race_details.first.race_players.first.pf_player_id
        current_promoter_year_summer_race_player_pf_player_id = current_promoter_year_summer_hold_daily.race_details.first.race_players.first.pf_player_id
        current_promoter_year_autumn_race_player_pf_player_id = current_promoter_year_autumn_hold_daily.race_details.first.race_players.first.pf_player_id
        current_promoter_year_winter_race_player_pf_player_id = current_promoter_year_winter_hold_daily.race_details.first.race_players.first.pf_player_id

        current_promoter_year_final_race_player_pf_250_regist_id = Player.find_by(pf_player_id: current_promoter_year_final_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        current_promoter_year_spring_race_player_pf_250_regist_id = Player.find_by(pf_player_id: current_promoter_year_spring_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        current_promoter_year_summer_race_player_pf_250_regist_id = Player.find_by(pf_player_id: current_promoter_year_summer_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        current_promoter_year_autumn_race_player_pf_250_regist_id = Player.find_by(pf_player_id: current_promoter_year_autumn_race_player_pf_player_id).player_original_info&.pf_250_regist_id
        current_promoter_year_winter_race_player_pf_250_regist_id = Player.find_by(pf_player_id: current_promoter_year_winter_race_player_pf_player_id).player_original_info&.pf_250_regist_id

        get_finalists
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(fiscal_year(Time.zone.now))
        expect(json['data']['final']['race_id']).to eq(current_promoter_year_final_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['final']['date']).to eq(current_promoter_year_final_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['final']['player_list'][0]).to eq(current_promoter_year_final_race_player_pf_250_regist_id)
        expect(json['data']['spring']['race_id']).to eq(current_promoter_year_spring_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['spring']['date']).to eq(current_promoter_year_spring_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['spring']['player_list'][0]).to eq(current_promoter_year_spring_race_player_pf_250_regist_id)
        expect(json['data']['summer']['race_id']).to eq(current_promoter_year_summer_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['summer']['date']).to eq(current_promoter_year_summer_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['summer']['player_list'][0]).to eq(current_promoter_year_summer_race_player_pf_250_regist_id)
        expect(json['data']['autumn']['race_id']).to eq(current_promoter_year_autumn_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['autumn']['date']).to eq(current_promoter_year_autumn_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['autumn']['player_list'][0]).to eq(current_promoter_year_autumn_race_player_pf_250_regist_id)
        expect(json['data']['winter']['race_id']).to eq(current_promoter_year_winter_hold_daily.races.find_by(event_code: '3').id)
        expect(json['data']['winter']['date']).to eq(current_promoter_year_winter_hold_daily.races.find_by(event_code: '3').race_detail.hold_day.to_date.strftime('%Y-%m-%d'))
        expect(json['data']['winter']['player_list'][0]).to eq(current_promoter_year_winter_race_player_pf_250_regist_id)
      end
    end

    context 'データがあるpromoter_yearを指定し、対応するレースがない場合' do
      let(:params) { { promoter_year: 2000 } }
      let(:final_hold_daily) { create(:hold_daily, hold: final_hold) }
      let(:spring_hold_daily) { create(:hold_daily, hold: spring_hold) }
      let(:summer_hold_daily) { create(:hold_daily, hold: summer_hold) }
      let(:autumn_hold_daily) { create(:hold_daily, hold: autumn_hold) }
      let(:winter_hold_daily) { create(:hold_daily, hold: winter_hold) }

      it 'race_idのパラメータが存在している' do
        get_finalists
        json = JSON.parse(response.body)
        expect(json['data']['final']).to have_key('race_id')
        expect(json['data']['spring']).to have_key('race_id')
        expect(json['data']['summer']).to have_key('race_id')
        expect(json['data']['autumn']).to have_key('race_id')
        expect(json['data']['winter']).to have_key('race_id')
      end
    end

    context 'パラメータを指定せず、対応するレースがない場合' do
      let(:params) { nil }
      let(:final_hold_daily) { create(:hold_daily, hold: final_hold) }
      let(:spring_hold_daily) { create(:hold_daily, hold: spring_hold) }
      let(:summer_hold_daily) { create(:hold_daily, hold: summer_hold) }
      let(:autumn_hold_daily) { create(:hold_daily, hold: autumn_hold) }
      let(:winter_hold_daily) { create(:hold_daily, hold: winter_hold) }

      it 'race_idのパラメータが存在している' do
        get_finalists
        json = JSON.parse(response.body)
        expect(json['data']['final']).to have_key('race_id')
        expect(json['data']['spring']).to have_key('race_id')
        expect(json['data']['summer']).to have_key('race_id')
        expect(json['data']['autumn']).to have_key('race_id')
        expect(json['data']['winter']).to have_key('race_id')
      end
    end
  end

  describe 'GET /seat_sales' do
    event_date1 = '20191231'
    event_date2 = '20200101'
    event_date3 = '20200201'

    let(:hold) { create(:hold, track_code: '01') }
    let(:hold_daily1) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date1)) }
    let(:hold_daily2) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date1)) }
    let(:hold_daily3) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date2)) }
    let(:hold_daily4) { create(:hold_daily, hold_id: hold.id, event_date: Time.zone.parse(event_date3)) }

    let(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1, daily_no: 0) }
    let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: hold_daily2, daily_no: 1) }
    let(:hold_daily_schedule3) { create(:hold_daily_schedule, hold_daily: hold_daily3, daily_no: 1) }
    let(:hold_daily_schedule4) { create(:hold_daily_schedule, hold_daily: hold_daily3, daily_no: 0) }
    let(:hold_daily_schedule5) { create(:hold_daily_schedule, hold_daily: hold_daily4, daily_no: 1) }
    let(:hold_daily_schedule6) { create(:hold_daily_schedule, hold_daily: hold_daily4, daily_no: 0) }

    let(:seat_sale1) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule1, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
    let(:seat_sale2) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule2, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(5..9).hour, force_sales_stop_at: Time.zone.now - rand(0..4).hour) }
    let(:seat_sale3) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule3, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
    let(:seat_sale4) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule4, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
    let(:seat_sale5) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule5, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }
    let(:seat_sale6) { create(:seat_sale, hold_daily_schedule:  hold_daily_schedule6, sales_status: 'on_sale', sales_start_at:  Time.zone.now - rand(0..4).hour) }

    it 'レスポンスパラメータが正しい（今日以降の開催の販売情報のみ返す）こと' do
      travel_to('2020-01-01 8:00') do
        hold
        seat_sale1
        seat_sale2
        seat_sale3
        seat_sale4
        get v1_mt_datas_seat_sales_path
        json = JSON.parse(response.body)

        expect(json['data']['select_time']).to eq(Time.zone.local(2020, 1, 1, 8, 0, 0).strftime('%F %T%:z'))
        expect(json['data']['seat_sales_list'][0]['id']).to eq(seat_sale4.id)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule4.id)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['promoter_year']).to eq(hold.promoter_year)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['season']).to eq(hold.period)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['round_code']).to eq(hold.round)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['event_date']).to eq(hold_daily3.event_date.strftime('%F'))
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['day_night']).to eq(hold_daily_schedule4.daily_no_before_type_cast)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['event_time']).to eq(hold_daily_schedule4.opening_display)

        expect(json['data']['seat_sales_list'][1]['id']).to eq(seat_sale3.id)
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['id']).to eq(hold_daily_schedule3.id)
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['promoter_year']).to eq(hold.promoter_year)
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['season']).to eq(hold.period)
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['round_code']).to eq(hold.round)
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['event_date']).to eq(hold_daily3.event_date.strftime('%F'))
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['day_night']).to eq(hold_daily_schedule3.daily_no_before_type_cast)
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['event_time']).to eq('16:30')
      end
    end

    it 'seat_salesが日付順で、デイ・ナイト順にソートして返す' do
      travel_to('2020-01-01 8:00') do
        hold
        seat_sale1
        seat_sale2
        seat_sale3
        seat_sale4
        seat_sale5
        seat_sale6
        get v1_mt_datas_seat_sales_path
        json = JSON.parse(response.body)
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['event_date']).to be <= json['data']['seat_sales_list'][1]['hold_daily_schedule']['event_date']
        expect(json['data']['seat_sales_list'][1]['hold_daily_schedule']['event_date']).to be <= json['data']['seat_sales_list'][2]['hold_daily_schedule']['event_date']
        expect(json['data']['seat_sales_list'][2]['hold_daily_schedule']['event_date']).to be <= json['data']['seat_sales_list'][3]['hold_daily_schedule']['event_date']
        expect(json['data']['seat_sales_list'][0]['hold_daily_schedule']['day_night']).to be <= json['data']['seat_sales_list'][1]['hold_daily_schedule']['day_night']
        expect(json['data']['seat_sales_list'][2]['hold_daily_schedule']['day_night']).to be <= json['data']['seat_sales_list'][3]['hold_daily_schedule']['day_night']
      end
    end
  end

  describe 'GET /annual_schedules' do
    promoter_year = 2020
    this_fiscal_year = Time.zone.now.month <= 3 ? Time.zone.now.year - 1 : Time.zone.now.year

    let!(:annual1) { create(:annual_schedule, pf_id: 'a1', promoter_year: promoter_year, first_day: '20200101', hold_days: 2, girl: false, audience: false, period: 1, round: 1, active: true) }
    let!(:annual2) { create(:annual_schedule, pf_id: 'a2', promoter_year: this_fiscal_year, first_day: Time.zone.today, hold_days: 2, girl: true, audience: true, period: 1, round: 1, active: true) }

    context 'パラメータpromoter_yearがある場合' do
      let!(:hold1) { create(:hold, first_day: annual1.first_day, period: 1, round: 1) }

      it 'レスポンスパラメータが正しいこと' do
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        json = JSON.parse(response.body)
        expect(json['data']['schedule_list'][0]['id']).to eq(annual1.id)
        expect(json['data']['schedule_list'][0]['event_date']).to eq(annual1.first_day.strftime('%F'))
        expect(json['data']['schedule_list'][0]['hold_days']).to eq(annual1.hold_days)
        expect(json['data']['schedule_list'][0]['girl']).to eq(annual1.girl)
        expect(json['data']['schedule_list'][0]['audience']).to eq(annual1.audience)
        expect(json['data']['schedule_list'][0]['promoter_year_title']).to eq(annual1.year_name)
        expect(json['data']['schedule_list'][0]['promoter_year_title_en']).to eq(annual1.year_name_en)
        expect(json['data']['schedule_list'][0]['season']).to eq(hold1.period)
        expect(json['data']['schedule_list'][0]['round']).to eq(hold1.round)
        expect(json['data']['schedule_list'][0]['active']).to eq(annual1.active)
        expect(json['data']['schedule_list'][0]['audience']).to eq(annual1.audience)
        expect(json['data']['schedule_list'][0]['grade_code']).to eq(annual1.grade_code)
        expect(json['data']['schedule_list'][0]['pre_day']).to eq(annual1.pre_day)
        expect(json['data']['schedule_list'][0]['promoter_section']).to eq(annual1.promoter_section)
        expect(json['data']['schedule_list'][0]['promoter_times']).to eq(annual1.promoter_times)
        expect(json['data']['schedule_list'][0]['promoter_year']).to eq(annual1.promoter_year)
        expect(json['data']['schedule_list'][0]['time_zone']).to eq(annual1.time_zone)
        expect(json['data']['schedule_list'][0]['track_code']).to eq(annual1.track_code)
        expect(json['data']['schedule_list'][0]['pf_id']).to eq(annual1.pf_id)
        expect(json['data']['schedule_list'][0]['created_at']).to eq(annual1.created_at.to_s)
        expect(json['data']['schedule_list'][0]['updated_at']).to eq(annual1.updated_at.to_s)
      end

      it 'event_date毎にレスポンスが返ること' do
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        json = JSON.parse(response.body)
        expect(json['data']['schedule_list'].size).to eq(2)
        expect(json['data']['schedule_list'][1]['event_date']).to eq((annual1.first_day + 1).strftime('%F'))
      end
    end

    context 'パラメータpromoter_yearがない場合' do
      it '今年度の年間スケジュールを返す' do
        get v1_mt_datas_annual_schedules_url
        json = JSON.parse(response.body)
        expect(json['data']['schedule_list'][0]['id']).to eq(annual2.id)
        expect(json['data']['schedule_list'][0]['event_date']).to eq(annual2.first_day.strftime('%F'))
        expect(json['data']['schedule_list'][0]['hold_days']).to eq(annual2.hold_days)
        expect(json['data']['schedule_list'][0]['girl']).to eq(annual2.girl)
        expect(json['data']['schedule_list'][0]['audience']).to eq(annual2.audience)
        expect(json['data']['schedule_list'][0]['promoter_year_title']).to eq(annual2.year_name)
        expect(json['data']['schedule_list'][0]['promoter_year_title_en']).to eq(annual2.year_name_en)
        expect(json['data']['schedule_list'][0]['season']).to eq(nil)
        expect(json['data']['schedule_list'][0]['round']).to eq(nil)
        expect(json['data']['schedule_list'][0]['active']).to eq(annual2.active)
        expect(json['data']['schedule_list'][0]['audience']).to eq(annual2.audience)
        expect(json['data']['schedule_list'][0]['grade_code']).to eq(annual2.grade_code)
        expect(json['data']['schedule_list'][0]['pre_day']).to eq(annual2.pre_day)
        expect(json['data']['schedule_list'][0]['promoter_section']).to eq(annual2.promoter_section)
        expect(json['data']['schedule_list'][0]['promoter_times']).to eq(annual2.promoter_times)
        expect(json['data']['schedule_list'][0]['promoter_year']).to eq(annual2.promoter_year)
        expect(json['data']['schedule_list'][0]['time_zone']).to eq(annual2.time_zone)
        expect(json['data']['schedule_list'][0]['track_code']).to eq(annual2.track_code)
        expect(json['data']['schedule_list'][0]['pf_id']).to eq(annual2.pf_id)
        expect(json['data']['schedule_list'][0]['created_at']).to eq(annual2.created_at.to_s)
        expect(json['data']['schedule_list'][0]['updated_at']).to eq(annual2.updated_at.to_s)
      end
    end

    context '前年度の3月と次年度4月の年間スケジュールが存在する場合' do
      let!(:annual3) { create(:annual_schedule, pf_id: 'a3', promoter_year: promoter_year - 1, first_day: "#{promoter_year}0301", hold_days: 2, girl: false, audience: false, period: 1, round: 1, active: true) }
      let!(:annual4) { create(:annual_schedule, pf_id: 'a4', promoter_year: promoter_year + 1, first_day: "#{promoter_year + 1}0401", hold_days: 2, girl: true, audience: true, period: 1, round: 1, active: true) }

      it '今年度、前年度3月、次年度4月の年間スケジュールを返す' do
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        json = JSON.parse(response.body)
        schedule_ids = json['data']['schedule_list'].pluck('id').uniq
        expect(schedule_ids).to include(annual1.id)
        expect(schedule_ids).to include(annual3.id)
        expect(schedule_ids).to include(annual4.id)
      end
    end

    context '必須のパラメータがない場合' do
      it 'activeがfalseの場合、取得できないこと' do
        [annual1, annual2].each { |annual| annual.update(active: false) }
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        expect(JSON.parse(response.body)['data']['schedule_list']).to be_blank
      end

      it 'first_dayがnilの場合、取得できないこと' do
        [annual1, annual2].each { |annual| annual.update(first_day: nil) }
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        expect(JSON.parse(response.body)['data']['schedule_list']).to be_blank
      end

      it 'hold_daysがnilの場合、取得できないこと' do
        [annual1, annual2].each { |annual| annual.update(hold_days: nil) }
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        expect(JSON.parse(response.body)['data']['schedule_list']).to be_blank
      end

      it 'girlがnilの場合、取得できないこと' do
        [annual1, annual2].each { |annual| annual.update(girl: nil) }
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        expect(JSON.parse(response.body)['data']['schedule_list']).to be_blank
      end

      it 'audienceがnilの場合、取得できないこと' do
        [annual1, annual2].each { |annual| annual.update(audience: nil) }
        get v1_mt_datas_annual_schedules_url, params: { promoter_year: promoter_year }
        expect(JSON.parse(response.body)['data']['schedule_list']).to be_blank
      end
    end
  end

  describe 'GET /rounds' do
    promoter_year = '2020'
    season = 'spring'

    context 'パラメータが誤っている場合（promoter_yearなし）' do
      subject(:get_rounds) { get v1_mt_datas_rounds_url, params: { season: season } }

      it 'エラーが発生すること' do
        get_rounds
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'bad_request', 'detail' => 'promoter_yearを入力してください', 'status' => 400 })
      end
    end

    context 'パラメータが正しいが、対象データがない場合' do
      subject(:get_rounds) { get v1_mt_datas_rounds_url, params: { promoter_year: promoter_year, season: season } }

      it 'レスポンスパラメータが正しいこと' do
        get_rounds
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(promoter_year.to_i)
        expect(json['data']['round_list']).to eq([])
      end
    end

    context 'パラメータが正しい場合' do
      subject(:get_rounds) { get v1_mt_datas_rounds_url, params: { promoter_year: promoter_year, season: season } }

      let(:hold1) { create(:hold, promoter_year: '2020', period: 1, round: 1, hold_status: 0) }
      let(:hold2) { create(:hold, promoter_year: '2020', period: 1, round: 2, hold_status: 3) }
      let(:hold3) { create(:hold, promoter_year: '2020', period: 2, round: 1) }
      let(:hold4) { create(:hold, promoter_year: '2021', period: 1, round: 1) }
      let(:hold5) { create(:hold, promoter_year: '2020', period: 1, round: nil) }
      let(:hold6) { create(:hold, promoter_year: '2020', round: 1, period: nil) }
      let(:hold7) { create(:hold, promoter_year: '2020', round: nil) }

      let(:word_code) { create(:word_code, identifier: '000', code: hold1.round) }
      let(:word_name) { create(:word_name, lang: 'jp', name: 'word_name', word_code_id: word_code.id) }

      let(:tt_result) { create(:time_trial_result, hold: hold2, pf_hold_id: hold2.pf_hold_id) }

      it 'ラウンドIDが存在しない場合、取得できないこと' do
        hold5
        get_rounds
        expect(JSON.parse(response.body)['data']['round_list']).to be_blank
      end

      it 'シーズンが存在しない場合、取得できないこと' do
        hold6
        get_rounds
        expect(JSON.parse(response.body)['data']['round_list']).to be_blank
      end

      it 'ラウンドIDとシーズンが存在しない場合、取得できないこと' do
        hold7
        get_rounds
        expect(JSON.parse(response.body)['data']['round_list']).to be_blank
      end

      it 'レスポンスパラメータが正しいこと' do
        hold1
        hold2
        hold3
        hold4
        word_name
        tt_result
        get_rounds
        json = JSON.parse(response.body)

        expect(json['data']['promoter_year']).to eq(promoter_year.to_i)
        expect(json['data']['round_list'][0]['code']).to eq(hold1.round)
        expect(json['data']['round_list'][0]['season']).to eq(hold1.period)
        expect(json['data']['round_list'][0]['hold_status']).to eq(1)
        expect(json['data']['round_list'][0]['first_day']).to eq(hold1.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['round_list'][0]['hold_days']).to eq(hold1.hold_days)
        expect(json['data']['round_list'][0]['has_tt_result']).to eq(hold1.time_trial_result.present?)
        expect(json['data']['round_list'][1]['code']).to eq(hold2.round)
        expect(json['data']['round_list'][1]['season']).to eq(hold1.period)
        expect(json['data']['round_list'][1]['hold_status']).to eq(2)
        expect(json['data']['round_list'][1]['first_day']).to eq(hold2.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['round_list'][1]['hold_days']).to eq(hold2.hold_days)
        expect(json['data']['round_list'][1]['has_tt_result']).to eq(hold2.time_trial_result.present?)
      end

      it 'first_dayで昇順ソートされていること' do
        hold1.update(first_day: '2020-10-01')
        hold2.update(first_day: '2020-10-02')
        hold3.update(period: 1, first_day: '2020-9-01')
        get_rounds
        json = JSON.parse(response.body)
        expect(json['data']['round_list'].pluck('first_day')).to eq(Hold.order(:first_day).map { |hold| hold.first_day.to_s })
      end
    end
  end

  describe 'GET /mediated_players' do
    subject(:get_mediated_players) { get v1_mt_datas_mediated_players_url, params: params }

    context '該当の開催がある開催年度、シーズン、ラウンドを指定した場合' do
      let!(:this_week_hold) { create(:hold, :with_mediated_players, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today, hold_status: 1) }
      let(:params) { { promoter_year: this_week_hold.promoter_year, season: this_week_hold.period, round_code: this_week_hold.round } }

      before do
        create(:hold, :with_mediated_players, promoter_year: 2021, period: 'summer', round: 1, first_day: Time.zone.today.next_week)
      end

      it '該当の開催情報が返る' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(this_week_hold.id)
        expect(json['data']['promoter_year']).to eq(this_week_hold.promoter_year)
        expect(json['data']['season']).to eq(this_week_hold.period)
        expect(json['data']['round_code']).to eq(this_week_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(this_week_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(this_week_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(this_week_hold.mediated_players.first.player.pf_250_regist_id)
        expect(json['data']['cancelled_list']).to eq []
        expect(json['data']['additional_list'].sort).to eq []
        expect(json['data']['absence_list']).to eq []
        expect(json['data']['updated_at']).to eq(this_week_hold.mediated_players.order(:updated_at).last.updated_at.to_s)
      end
    end

    context 'リクエストパラメータにpromoter_yearを指定しない場合' do
      before do
        create(:hold, :with_mediated_players, promoter_year: 2021, period: 'summer', round: 1, first_day: Time.zone.today.next_week)
      end

      let!(:this_week_hold) { create(:hold, :with_mediated_players, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today) }
      let(:params) { { promoter_year: nil, season: 'spring', round_code: 1 } }

      it '今週の情報取得' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(this_week_hold.id)
      end
    end

    context '開催にpromoter_yearがない場合' do
      before do
        create(:hold, :with_mediated_players, promoter_year: nil, period: 'summer', round: 1)
      end

      it '空を渡すことを確認' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'summer', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context '開催にperiodがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: nil, round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: nil, round: 1) }

      before do
        spring_hold
        summer_hold
      end

      it '空を渡すことを確認' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'summer', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context '開催にラウンドがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: nil) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: nil) }

      before do
        spring_hold
        summer_hold
      end

      it '空を渡すことを確認' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'spring', round_code: 1)
      end
    end

    context '該当の開催がない開催年度、シーズン、ラウンドを指定した場合' do
      let(:params) { { promoter_year: 2021, season: 'winter', round_code: 1 } }

      it 'nilが返る' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'pf_250_regist_idがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        PlayerOriginalInfo.update_all(pf_250_regist_id: nil)
      end

      it 'player_listの中にpf_250_regist_idが取得できていない' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end
    end

    context 'first_name_enがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        PlayerOriginalInfo.update_all(first_name_en: nil)
      end

      it 'player_listの中にfirst_name_enが取得できていない' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end
    end

    context 'last_name_enがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        PlayerOriginalInfo.update_all(last_name_en: nil)
      end

      it 'player_listの中にlast_name_enが取得できていない' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end
    end

    context 'miss_dayに値が入っている場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        MediatedPlayer.update_all(miss_day: 'test')
      end

      it 'player_listが取得できていないこと' do
        get v1_mt_datas_mediated_players_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end

      it 'cancelled_listが取得できること' do
        get v1_mt_datas_mediated_players_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['cancelled_list'][0]).to eq(spring_hold.mediated_players.first.player.pf_250_regist_id)
      end
    end

    context '出場選手と欠場選手が混在する場合' do
      let(:hold) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:hold_daily) { create(:hold_daily, event_date: Time.zone.now, hold: hold) }

      let(:player) { create(:player, :with_original_info) }
      let(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:mediated_player) { create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id) }

      let(:player_miss_day_1) { create(:player, :with_original_info) }
      let(:hold_player_miss_day_1) { create(:hold_player, hold: hold, player: player_miss_day_1) }
      let(:mediated_player_miss_day_1) { create(:mediated_player, hold_player: hold_player_miss_day_1, pf_player_id: player_miss_day_1.pf_player_id, miss_day: 'miss_day') }

      let(:player_miss_day_2) { create(:player, :with_original_info) }
      let(:hold_player_miss_day_2) { create(:hold_player, hold: hold, player: player_miss_day_2) }
      let(:mediated_player_miss_day_2) { create(:mediated_player, hold_player: hold_player_miss_day_2, pf_player_id: player_miss_day_2.pf_player_id, miss_day: 'miss_day') }

      before do
        mediated_player
        mediated_player_miss_day_1
        mediated_player_miss_day_2
      end

      it 'player_listとcancelled_listが取得できること' do
        get v1_mt_datas_mediated_players_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]).to eq(mediated_player.player.pf_250_regist_id)
        expect(json['data']['cancelled_list'].sort).to eq([mediated_player_miss_day_1.player.pf_250_regist_id, mediated_player_miss_day_2.player.pf_250_regist_id].sort)
      end
    end

    context '出場選手、欠場選手、補充選手、途中欠場選手が混在する場合' do
      let(:hold) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:hold_daily) { create(:hold_daily, event_date: Time.zone.now, hold: hold) }

      let(:player) { create(:player, :with_original_info) }
      let(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:mediated_player) { create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id) }

      let(:player_miss_day_1) { create(:player, :with_original_info) }
      let(:hold_player_miss_day_1) { create(:hold_player, hold: hold, player: player_miss_day_1) }
      let(:mediated_player_miss_day_1) { create(:mediated_player, hold_player: hold_player_miss_day_1, pf_player_id: player_miss_day_1.pf_player_id, miss_day: 'miss_day') }

      let(:player_absence) { create(:player) }
      let(:player_original_info) { create(:player_original_info, player: player_absence, last_name_jp: '田中', first_name_jp: '太郎') }
      let(:hold_player_absence) { create(:hold_player, hold: hold, player: player_original_info.player) }
      let(:mediated_player_absence) { create(:mediated_player, hold_player: hold_player_absence, pf_player_id: player_absence.pf_player_id, miss_day: 'miss_day', join_code: '100') }

      let(:player_additional) { create(:player, :with_original_info) }
      let(:hold_player_additional) { create(:hold_player, hold: hold, player: player_additional) }
      let(:mediated_player_additional) { create(:mediated_player, hold_player: hold_player_additional, pf_player_id: player_additional.pf_player_id, issue_code: '410',) }

      let(:player_additional2) { create(:player, :with_original_info) }
      let(:hold_player_additional2) { create(:hold_player, hold: hold, player: player_additional2) }
      let(:mediated_player_additional2) { create(:mediated_player, hold_player: hold_player_additional2, pf_player_id: player_additional2.pf_player_id, issue_code: '420', miss_day: 'miss_day', join_code: '110', updated_at: Time.zone.now + 10.days) }

      let(:player_additional3) { create(:player, :with_original_info) }
      let(:hold_player_additional3) { create(:hold_player, hold: hold, player: player_additional3) }
      let(:mediated_player_additional3) { create(:mediated_player, hold_player: hold_player_additional3, pf_player_id: player_additional3.pf_player_id, issue_code: '300', miss_day: 'miss_day') }

      before do
        mediated_player
        mediated_player_miss_day_1
        mediated_player_absence
        mediated_player_additional
        mediated_player_additional2
        mediated_player_additional3
      end

      it 'player_list,cancelled_list,additional_list,absence_listが取得できること（補充選手と途中欠場選手は重複することがある）' do
        get v1_mt_datas_mediated_players_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list'].sort).to eq([mediated_player.player.pf_250_regist_id, mediated_player_absence.pf_250_regist_id].sort)
        expect(json['data']['cancelled_list'].sort).to eq([mediated_player_miss_day_1.player.pf_250_regist_id, mediated_player_additional3.player.pf_250_regist_id].sort)
        expect(json['data']['additional_list'].sort).to eq([mediated_player_additional.player.pf_250_regist_id, mediated_player_additional2.player.pf_250_regist_id, mediated_player_additional3.player.pf_250_regist_id].sort)
        expect(json['data']['absence_list'].sort).to eq([mediated_player_absence.full_name, mediated_player_additional2.full_name].sort)
      end

      it 'updated_atはリストの中から一番大きい値が返されること' do
        get v1_mt_datas_mediated_players_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['updated_at']).to eq(mediated_player_additional2.updated_at.to_s)
      end

      it 'absence_list内の名前がない場合は、' do
      end
    end

    context 'promoter_yearを指定して、シーズンを指定しない場合' do
      let(:params) { { promoter_year: 2021, season: nil, round_code: 1 } }

      it 'bad_requestエラーが返る' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end

    context 'promoter_yearを指定して、ラウンドを指定しない場合' do
      let(:params) { { promoter_year: 2021, season: 'spring', round_code: nil } }

      it 'bad_requestエラーが返る' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end

    context '開催初日が1日前のholdがあり、開催年度、シーズン、ラウンドを指定しない場合' do
      let(:params) { nil }
      let!(:yesterday_start_hold) { create(:hold, :with_mediated_players, first_day: Time.zone.today.yesterday, period: 'spring', hold_status: 1) }

      before do
        create(:hold, :with_mediated_players, first_day: Time.zone.today.tomorrow, period: 'spring')
      end

      it '1日前開催開始のholdを取得' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(yesterday_start_hold.id)
        expect(json['data']['promoter_year']).to eq(yesterday_start_hold.promoter_year)
        expect(json['data']['season']).to eq(yesterday_start_hold.period)
        expect(json['data']['round_code']).to eq(yesterday_start_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(yesterday_start_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(yesterday_start_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(yesterday_start_hold.mediated_players.first.pf_250_regist_id)
        expect(json['data']['cancelled_list']).to eq []
      end
    end

    context '開催初日が2日前のholdがあり、開催年度、シーズン、ラウンドを指定しない場合' do
      let(:params) { nil }
      let!(:tomorrow_start_hold) { create(:hold, :with_mediated_players, first_day: Time.zone.today.tomorrow, period: 'spring', hold_status: 1) }

      before do
        create(:hold, :with_mediated_players, first_day: Time.zone.today.prev_day(2), period: 'spring')
        create(:hold, :with_mediated_players, first_day: Time.zone.today.next_day(7), period: 'spring')
      end

      it '将来の最初の開催開始のholdを取得' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(tomorrow_start_hold.id)
        expect(json['data']['promoter_year']).to eq(tomorrow_start_hold.promoter_year)
        expect(json['data']['season']).to eq(tomorrow_start_hold.period)
        expect(json['data']['round_code']).to eq(tomorrow_start_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(tomorrow_start_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(tomorrow_start_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(tomorrow_start_hold.mediated_players.first.pf_250_regist_id)
        expect(json['data']['cancelled_list']).to eq []
      end
    end

    context '開催初日が2日前以降の開催がなく、開催年度、シーズン、ラウンドを指定しない場合' do
      let(:params) { nil }
      let!(:two_days_ago_start_hold) { create(:hold, :with_mediated_players, first_day: Time.zone.today.prev_day(2), period: 'spring', hold_status: 1) }

      before do
        create(:hold, :with_mediated_players, first_day: Time.zone.today.prev_day(7), period: 'spring')
      end

      it '過去の直近の開催情報を取得' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(two_days_ago_start_hold.id)
        expect(json['data']['promoter_year']).to eq(two_days_ago_start_hold.promoter_year)
        expect(json['data']['season']).to eq(two_days_ago_start_hold.period)
        expect(json['data']['round_code']).to eq(two_days_ago_start_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(two_days_ago_start_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(two_days_ago_start_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(two_days_ago_start_hold.mediated_players.first.pf_250_regist_id)
        expect(json['data']['cancelled_list']).to eq []
      end
    end

    context 'promoter_yearがない開催があり、リクエストパラメータを指定しない場合、' do
      before do
        create(:hold, promoter_year: nil, period: nil, round: 1, first_day: Time.zone.today.prev_day(1))
      end

      let!(:hold_with_promoter_year) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, first_day: Time.zone.today.prev_day(2)) }

      let(:params) { nil }

      it 'promoter_yearがない開催が返らないこと' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(hold_with_promoter_year.id)
      end
    end

    context 'periodがない開催があり、リクエストパラメータを指定しない場合、' do
      before do
        create(:hold, promoter_year: Time.zone.now.year, period: nil, round: 1, first_day: Time.zone.today.prev_day(1))
      end

      let!(:hold_with_period) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, first_day: Time.zone.today.prev_day(2)) }

      let(:params) { nil }

      it 'promoter_yearがない開催が返らないこと' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(hold_with_period.id)
      end
    end

    context 'roundがない開催があり、リクエストパラメータを指定しない場合、' do
      before do
        create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: nil, first_day: Time.zone.today.prev_day(1))
      end

      let!(:hold_with_round) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, first_day: Time.zone.today.prev_day(2)) }

      let(:params) { nil }

      it 'roundがない開催が返らないこと' do
        get_mediated_players
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(hold_with_round.id)
      end
    end
  end

  describe 'GET /mediated_players_revision' do
    subject(:get_mediated_players_revision) { get v1_mt_datas_mediated_players_revision_url, params: params }

    context '該当の開催がある開催年度、シーズン、ラウンドを指定した場合' do
      let!(:this_week_hold) { create(:hold, :with_mediated_players, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today) }
      let(:params) { { promoter_year: this_week_hold.promoter_year, season: this_week_hold.period, round_code: this_week_hold.round } }
      let(:player_summary) do
        player = this_week_hold.mediated_players.first.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        create(:hold, :with_mediated_players, promoter_year: 2021, period: 'summer', round: 1, first_day: Time.zone.today.next_week, hold_status: 1)
      end

      it '該当の開催情報が返る' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(this_week_hold.id)
        expect(json['data']['promoter_year']).to eq(this_week_hold.promoter_year)
        expect(json['data']['season']).to eq(this_week_hold.period)
        expect(json['data']['round_code']).to eq(this_week_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(this_week_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(this_week_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(player_summary)
        expect(json['data']['cancelled_list']).to eq []
        expect(json['data']['additional_list'].sort).to eq []
        expect(json['data']['absence_list']).to eq []
        expect(json['data']['updated_at']).to eq(this_week_hold.mediated_players.order(:updated_at).last.updated_at.to_s)
      end
    end

    context 'リクエストパラメータにpromoter_yearを指定しない場合' do
      before do
        create(:hold, :with_mediated_players, promoter_year: 2021, period: 'summer', round: 1, first_day: Time.zone.today.next_week)
      end

      let!(:this_week_hold) { create(:hold, :with_mediated_players, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today) }
      let(:params) { { promoter_year: nil, season: 'spring', round_code: 1 } }

      it '今週の情報取得' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(this_week_hold.id)
      end
    end

    context '開催にpromoter_yearがない場合' do
      before do
        create(:hold, :with_mediated_players, promoter_year: nil, period: 'summer', round: 1)
      end

      it '空を渡すことを確認' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'summer', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context '開催にperiodがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: nil, round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: nil, round: 1) }

      before do
        spring_hold
        summer_hold
      end

      it '空を渡すことを確認' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'summer', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context '開催にラウンドがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: nil) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: nil) }

      before do
        spring_hold
        summer_hold
      end

      it '空を渡すことを確認' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'spring', round_code: 1)
      end
    end

    context '該当の開催がない開催年度、シーズン、ラウンドを指定した場合' do
      let(:params) { { promoter_year: 2021, season: 'winter', round_code: 1 } }

      it 'nilが返る' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'pf_250_regist_idがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        PlayerOriginalInfo.update_all(pf_250_regist_id: nil)
      end

      it 'player_listの中にpf_250_regist_idが取得できていない' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end
    end

    context 'first_name_enがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        PlayerOriginalInfo.update_all(first_name_en: nil)
      end

      it 'player_listの中にfirst_name_enが取得できていない' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end
    end

    context 'last_name_enがない場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: Time.zone.now.year, period: 'summer', round: 1) }

      before do
        spring_hold
        summer_hold
        PlayerOriginalInfo.update_all(last_name_en: nil)
      end

      it 'player_listの中にlast_name_enが取得できていない' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end
    end

    context 'miss_dayに値が入っている場合' do
      let(:spring_hold) { create(:hold, :with_mediated_players, promoter_year: 2021, period: 'spring', round: 1) }
      let(:summer_hold) { create(:hold, :with_mediated_players, promoter_year: 2021, period: 'summer', round: 1) }
      let(:player_summary) do
        player = spring_hold.mediated_players.first.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        spring_hold
        summer_hold
        MediatedPlayer.update_all(miss_day: 'test')
      end

      it 'player_listが取得できていないこと' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: nil, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to eq []
      end

      it 'cancelled_listが取得できること' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: 2021, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['cancelled_list'][0]).to eq(player_summary)
      end
    end

    context '出場選手と欠場選手が混在する場合' do
      let(:hold) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:hold_daily) { create(:hold_daily, event_date: Time.zone.now, hold: hold) }

      let(:player) { create(:player, :with_original_info) }
      let(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:mediated_player) { create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id) }

      let(:player_miss_day_1) { create(:player, :with_original_info) }
      let(:hold_player_miss_day_1) { create(:hold_player, hold: hold, player: player_miss_day_1) }
      let(:mediated_player_miss_day_1) { create(:mediated_player, hold_player: hold_player_miss_day_1, pf_player_id: player_miss_day_1.pf_player_id, miss_day: 'miss_day') }

      let(:player_miss_day_2) { create(:player, :with_original_info) }
      let(:hold_player_miss_day_2) { create(:hold_player, hold: hold, player: player_miss_day_2) }
      let(:mediated_player_miss_day_2) { create(:mediated_player, hold_player: hold_player_miss_day_2, pf_player_id: player_miss_day_2.pf_player_id, miss_day: 'miss_day') }
      let(:player_summary) do
        player = mediated_player.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:mediated_player1_summary) do
        player = mediated_player_miss_day_1.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:mediated_player2_summary) do
        player = mediated_player_miss_day_2.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        mediated_player
        mediated_player_miss_day_1
        mediated_player_miss_day_2
      end

      it 'player_listとcancelled_listが取得できること' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]).to eq(player_summary)
        expect(json['data']['cancelled_list'].find { |j| j['id'] == mediated_player_miss_day_1.player.pf_250_regist_id }).to eq(mediated_player1_summary)
        expect(json['data']['cancelled_list'].find { |j| j['id'] == mediated_player_miss_day_2.player.pf_250_regist_id }).to eq(mediated_player2_summary)
      end
    end

    context '出場選手、欠場選手、補充選手、途中欠場選手が混在する場合' do
      let(:hold) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1) }
      let(:hold_daily) { create(:hold_daily, event_date: Time.zone.now, hold: hold) }

      let(:player) { create(:player, :with_original_info) }
      let(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:mediated_player) { create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id) }

      let(:player_miss_day_1) { create(:player, :with_original_info) }
      let(:hold_player_miss_day_1) { create(:hold_player, hold: hold, player: player_miss_day_1) }
      let(:mediated_player_miss_day_1) { create(:mediated_player, hold_player: hold_player_miss_day_1, pf_player_id: player_miss_day_1.pf_player_id, miss_day: 'miss_day') }

      let(:player_absence) { create(:player) }
      let(:player_original_info) { create(:player_original_info, player: player_absence, last_name_jp: '田中', first_name_jp: '太郎') }
      let(:hold_player_absence) { create(:hold_player, hold: hold, player: player_original_info.player) }
      let(:mediated_player_absence) { create(:mediated_player, hold_player: hold_player_absence, pf_player_id: player_absence.pf_player_id, miss_day: 'miss_day', join_code: '100') }

      let(:player_additional) { create(:player, :with_original_info) }
      let(:hold_player_additional) { create(:hold_player, hold: hold, player: player_additional) }
      let(:mediated_player_additional) { create(:mediated_player, hold_player: hold_player_additional, pf_player_id: player_additional.pf_player_id, issue_code: '410',) }

      let(:player_additional2) { create(:player, :with_original_info) }
      let(:hold_player_additional2) { create(:hold_player, hold: hold, player: player_additional2) }
      let(:mediated_player_additional2) { create(:mediated_player, hold_player: hold_player_additional2, pf_player_id: player_additional2.pf_player_id, issue_code: '420', miss_day: 'miss_day', join_code: '110', updated_at: Time.zone.now + 10.days) }

      let(:player_additional3) { create(:player, :with_original_info) }
      let(:hold_player_additional3) { create(:hold_player, hold: hold, player: player_additional3) }
      let(:mediated_player_additional3) { create(:mediated_player, hold_player: hold_player_additional3, pf_player_id: player_additional3.pf_player_id, issue_code: '300', miss_day: 'miss_day') }
      let(:player_summary) do
        player = mediated_player.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:canceled_player_summary) do
        player = mediated_player_miss_day_1.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:additional_player1_summary) do
        player = mediated_player_additional.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:additional_player2_summary) do
        player = mediated_player_additional2.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:additional_player3_summary) do
        player = mediated_player_additional3.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end
      let(:absence_player_summary) do
        player = mediated_player_absence.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        mediated_player
        mediated_player_miss_day_1
        mediated_player_absence
        mediated_player_additional
        mediated_player_additional2
        mediated_player_additional3
      end

      it 'player_list,cancelled_list,additional_list,absence_listが取得できること（補充選手と途中欠場選手は重複することがある）' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]).to eq(player_summary)
        expect(json['data']['cancelled_list'][0]).to eq(canceled_player_summary)
        expect(json['data']['additional_list'].find { |j| j['id'] == mediated_player_additional.player.pf_250_regist_id }).to eq(additional_player1_summary)
        expect(json['data']['additional_list'].find { |j| j['id'] == mediated_player_additional2.player.pf_250_regist_id }).to eq(additional_player2_summary)
        expect(json['data']['additional_list'].find { |j| j['id'] == mediated_player_additional3.player.pf_250_regist_id }).to eq(additional_player3_summary)
        expect(json['data']['absence_list'].find { |j| j['id'] == mediated_player_absence.player.pf_250_regist_id }).to eq(absence_player_summary)
        expect(json['data']['absence_list'].find { |j| j['id'] == mediated_player_additional2.player.pf_250_regist_id }).to eq(additional_player2_summary)
      end

      it 'updated_atはリストの中から一番大きい値が返されること' do
        get v1_mt_datas_mediated_players_revision_url(promoter_year: Time.zone.now.year, season: 'spring', round_code: 1)
        json = JSON.parse(response.body)
        expect(json['data']['updated_at']).to eq(mediated_player_additional2.updated_at.to_s)
      end

      it 'absence_list内の名前がない場合は、' do
      end
    end

    context 'promoter_yearを指定して、シーズンを指定しない場合' do
      let(:params) { { promoter_year: 2021, season: nil, round_code: 1 } }

      it 'bad_requestエラーが返る' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end

    context 'promoter_yearを指定して、ラウンドを指定しない場合' do
      let(:params) { { promoter_year: 2021, season: 'spring', round_code: nil } }

      it 'bad_requestエラーが返る' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end

    context '開催初日が1日前のholdがあり、開催年度、シーズン、ラウンドを指定しない場合' do
      let(:params) { nil }
      let!(:yesterday_start_hold) { create(:hold, :with_mediated_players, first_day: Time.zone.today.yesterday, period: 'spring', hold_status: 1) }
      let(:player_summary) do
        player = yesterday_start_hold.mediated_players.first.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        create(:hold, :with_mediated_players, first_day: Time.zone.today.tomorrow, period: 'spring')
      end

      it '1日前開催開始のholdを取得' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(yesterday_start_hold.id)
        expect(json['data']['promoter_year']).to eq(yesterday_start_hold.promoter_year)
        expect(json['data']['season']).to eq(yesterday_start_hold.period)
        expect(json['data']['round_code']).to eq(yesterday_start_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(yesterday_start_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(yesterday_start_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(player_summary)
        expect(json['data']['cancelled_list']).to eq []
      end
    end

    context '開催初日が2日前のholdがあり、開催年度、シーズン、ラウンドを指定しない場合' do
      let(:params) { nil }
      let!(:tomorrow_start_hold) { create(:hold, :with_mediated_players, first_day: Time.zone.today.tomorrow, period: 'spring', hold_status: 1) }
      let(:player_summary) do
        player = tomorrow_start_hold.mediated_players.first.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        create(:hold, :with_mediated_players, first_day: Time.zone.today.prev_day(2), period: 'spring')
        create(:hold, :with_mediated_players, first_day: Time.zone.today.next_day(7), period: 'spring')
      end

      it '将来の最初の開催開始のholdを取得' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(tomorrow_start_hold.id)
        expect(json['data']['promoter_year']).to eq(tomorrow_start_hold.promoter_year)
        expect(json['data']['season']).to eq(tomorrow_start_hold.period)
        expect(json['data']['round_code']).to eq(tomorrow_start_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(tomorrow_start_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(tomorrow_start_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(player_summary)
        expect(json['data']['cancelled_list']).to eq []
      end
    end

    context '開催初日が2日前以降の開催がなく、開催年度、シーズン、ラウンドを指定しない場合' do
      let(:params) { nil }
      let!(:two_days_ago_start_hold) { create(:hold, :with_mediated_players, first_day: Time.zone.today.prev_day(2), period: 'spring') }
      let(:player_summary) do
        player = two_days_ago_start_hold.mediated_players.first.player
        {
          'id' => player.pf_250_regist_id,
          'last_name_jp' => player.last_name_jp,
          'first_name_jp' => player.first_name_jp,
          'country_code' => player.player_original_info.free2
        }
      end

      before do
        create(:hold, :with_mediated_players, first_day: Time.zone.today.prev_day(7), period: 'spring', hold_status: 1)
      end

      it '過去の直近の開催情報を取得' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(two_days_ago_start_hold.id)
        expect(json['data']['promoter_year']).to eq(two_days_ago_start_hold.promoter_year)
        expect(json['data']['season']).to eq(two_days_ago_start_hold.period)
        expect(json['data']['round_code']).to eq(two_days_ago_start_hold.round)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(two_days_ago_start_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(two_days_ago_start_hold.hold_days)
        expect(json['data']['player_list'][0]).to eq(player_summary)
        expect(json['data']['cancelled_list']).to eq []
      end
    end

    context 'promoter_yearがない開催があり、リクエストパラメータを指定しない場合、' do
      before do
        create(:hold, promoter_year: nil, period: nil, round: 1, first_day: Time.zone.today.prev_day(1))
      end

      let!(:hold_with_promoter_year) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, first_day: Time.zone.today.prev_day(2)) }

      let(:params) { nil }

      it 'promoter_yearがない開催が返らないこと' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(hold_with_promoter_year.id)
      end
    end

    context 'periodがない開催があり、リクエストパラメータを指定しない場合、' do
      before do
        create(:hold, promoter_year: Time.zone.now.year, period: nil, round: 1, first_day: Time.zone.today.prev_day(1))
      end

      let!(:hold_with_period) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, first_day: Time.zone.today.prev_day(2)) }

      let(:params) { nil }

      it 'promoter_yearがない開催が返らないこと' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(hold_with_period.id)
      end
    end

    context 'roundがない開催があり、リクエストパラメータを指定しない場合、' do
      before do
        create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: nil, first_day: Time.zone.today.prev_day(1))
      end

      let!(:hold_with_round) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, first_day: Time.zone.today.prev_day(2)) }

      let(:params) { nil }

      it 'roundがない開催が返らないこと' do
        get_mediated_players_revision
        json = JSON.parse(response.body)
        expect(json['data']['hold_id']).to eq(hold_with_round.id)
      end
    end
  end

  describe 'GET /time_trial_results' do
    subject(:player_detail_key) { %w[id last_name_jp first_name_jp last_name_en first_name_en birthday height weight country_code catchphrase speed stamina power technique mental evaluation round_best year_best major_title pist6_title winner_rate first_place_count second_place_count first_count round_result_list] }

    let(:get_time_trial_results) { get v1_mt_datas_time_trial_results_url, params: params }
    let(:player) { create(:player, pf_player_id: '1234') }

    before do
      create(:player_original_info, player: player, pf_250_regist_id: 111)
    end

    context 'promoter_year, season, round_codeのすべてのパラメータが入力され、該当の開催情報・タイムトライアル結果が存在する場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, hold_status: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let!(:tt_player) { create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 12.34, ranking: 1, gear: 1.2) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      it '該当の開催情報・タイムトライアル結果が返る' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(spring_hold.promoter_year)
        expect(json['data']['season']).to eq(spring_hold.period)
        expect(json['data']['round_code']).to eq(spring_hold.round)
        expect(json['data']['hold_id']).to eq(spring_hold.id)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(spring_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(spring_hold.hold_days)
        expect(json['data']['tt_movie_yt_id']).to eq(spring_hold.tt_movie_yt_id)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(tt_player.total_time.to_f)
        expect(json['data']['tt_result_list'][0]['rank']).to eq(tt_player.ranking)
        expect(json['data']['tt_result_list'][0]['gear']).to eq(tt_player.gear.to_f)
        expect(json['data']['tt_result_list'][0]['player']['id']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).pf_250_regist_id)
        expect(json['data']['tt_result_list'][0]['player'].keys).to match_array(player_detail_key)
      end
    end

    context 'パラメータを指定しない場合' do
      let(:this_week_hold) { create(:hold, period: 'spring', round: 1, first_day: Time.zone.today, hold_status: 1) }
      let(:tt_result) { create(:time_trial_result, hold: this_week_hold, pf_hold_id: this_week_hold.pf_hold_id) }
      let!(:tt_player) { create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 2) }
      let(:params) { nil }

      it '今週開催の情報（月曜更新）が取得される' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(this_week_hold.promoter_year)
        expect(json['data']['season']).to eq(this_week_hold.period)
        expect(json['data']['round_code']).to eq(this_week_hold.round)
        expect(json['data']['hold_id']).to eq(this_week_hold.id)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(this_week_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(this_week_hold.hold_days)
        expect(json['data']['tt_movie_yt_id']).to eq(this_week_hold.tt_movie_yt_id)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(this_week_hold.time_trial_result.time_trial_players.first.total_time)
        expect(json['data']['tt_result_list'][0]['rank']).to eq(this_week_hold.time_trial_result.time_trial_players.first.ranking)
        expect(json['data']['tt_result_list'][0]['player']['id']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).pf_250_regist_id)
        expect(json['data']['tt_result_list'][0]['player'].keys).to match_array(player_detail_key)
      end
    end

    context 'tt_playerが複数ある場合' do
      let(:this_week_hold) { create(:hold, period: 'spring', round: 1, first_day: Time.zone.today) }
      let(:tt_result) { create(:time_trial_result, hold: this_week_hold, pf_hold_id: this_week_hold.pf_hold_id) }
      let(:params) { nil }

      it 'rank順にソートして取得される' do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 12)
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 4)
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 13)
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['rank']).to eq 4
        expect(json['data']['tt_result_list'][1]['rank']).to eq 12
        expect(json['data']['tt_result_list'][2]['rank']).to eq 13
      end
    end

    context 'promoter_yearが指定されていて、season, round_codeが指定されていない場合' do
      let(:params) { { promoter_year: 2021 } }

      it 'bad_requestエラーが返る' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end

    context '開催情報はあるが、タイムトライアル結果がない場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, hold_status: 1) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      it '開催情報が出力される' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(spring_hold.promoter_year)
        expect(json['data']['season']).to eq(spring_hold.period)
        expect(json['data']['round_code']).to eq(spring_hold.round)
        expect(json['data']['hold_id']).to eq(spring_hold.id)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(spring_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(spring_hold.hold_days)
        expect(json['data']['tt_movie_yt_id']).to eq(spring_hold.tt_movie_yt_id)
      end

      it '空のtt_result_listが返る' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list']).to eq([])
      end
    end

    context 'paramsを指定しない場合' do
      let(:params) { nil }

      context '今週の開催のpromoter_year, series, round_codeがない場合、' do
        before do
          create(:hold, promoter_year: nil, period: 'spring', round: 1, first_day: Time.zone.today)
        end

        it 'nilが返る' do
          get_time_trial_results
          json = JSON.parse(response.body)
          expect(json['data']).to eq(nil)
        end
      end

      context 'periodがない場合、' do
        before do
          create(:hold, promoter_year: 2021, period: nil, round: 1, first_day: Time.zone.today)
        end

        it 'nilが返る' do
          get_time_trial_results
          json = JSON.parse(response.body)
          expect(json['data']).to eq(nil)
        end
      end

      context 'round_codeがない場合、' do
        before do
          create(:hold, promoter_year: 2021, period: 'spring', round: nil, first_day: Time.zone.today)
        end

        it 'nilが返る' do
          get_time_trial_results
          json = JSON.parse(response.body)
          expect(json['data']).to eq(nil)
        end
      end
    end

    context 'PlayerOriginalInfoのlast_name_enがnilの場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 12.34, ranking: 1)
        player.player_original_info.update_column(:last_name_en, nil)
      end

      it 'playerがnilで返ってくること' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['player']).to eq(nil)
      end
    end

    context 'PlayerOriginalInfoのfirst_name_enがnilの場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 12.34, ranking: 1)
        player.player_original_info.update_column(:first_name_en, nil)
      end

      it 'playerがnilで返ってくること' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['player']).to eq(nil)
      end
    end

    context 'PlayerOriginalInfoのpf_250_regist_idがnilの場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 12.34, ranking: 1)
        player.player_original_info.update_column(:pf_250_regist_id, nil)
      end

      it 'playerがnilで返ってくること' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['player']).to eq(nil)
      end
    end

    context 'total_timeが99.9999の場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 99.9999)
      end

      it 'total_timeがnilで返ってくること' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(nil)
      end
    end

    context 'total_timeが99.999の場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 99.999)
      end

      it 'total_timeがnilで返ってくること' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(nil)
      end
    end

    context 'total_timeがnilの場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: nil)
      end

      it 'total_timeがnilで返ってくること' do
        get_time_trial_results
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(nil)
      end
    end
  end

  describe 'GET /time_trial_results_revision' do
    subject(:get_time_trial_results_revision) { get v1_mt_datas_time_trial_results_revision_url, params: params }

    let(:player) { create(:player, pf_player_id: '1234') }

    before do
      create(:player_original_info, player: player, pf_250_regist_id: 111)
    end

    context 'promoter_year, season, round_codeのすべてのパラメータが入力され、該当の開催情報・タイムトライアル結果が存在する場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, hold_status: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let!(:tt_player) { create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 12.34, ranking: 1, gear: 1.2) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      it '該当の開催情報・タイムトライアル結果が返る' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(spring_hold.promoter_year)
        expect(json['data']['season']).to eq(spring_hold.period)
        expect(json['data']['round_code']).to eq(spring_hold.round)
        expect(json['data']['hold_id']).to eq(spring_hold.id)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(spring_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(spring_hold.hold_days)
        expect(json['data']['tt_movie_yt_id']).to eq(spring_hold.tt_movie_yt_id)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(tt_player.total_time.to_f)
        expect(json['data']['tt_result_list'][0]['rank']).to eq(tt_player.ranking)
        expect(json['data']['tt_result_list'][0]['gear']).to eq(tt_player.gear.to_f)
        expect(json['data']['tt_result_list'][0]['pf_250_regist_id']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).pf_250_regist_id)
        expect(json['data']['tt_result_list'][0]['country_code']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).player_original_info.free2)
        expect(json['data']['tt_result_list'][0]['first_name_jp']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).player_original_info.first_name_jp)
        expect(json['data']['tt_result_list'][0]['last_name_jp']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).player_original_info.last_name_jp)
      end
    end

    context 'パラメータを指定しない場合' do
      let(:this_week_hold) { create(:hold, period: 'spring', round: 1, first_day: Time.zone.today, hold_status: 1) }
      let(:tt_result) { create(:time_trial_result, hold: this_week_hold, pf_hold_id: this_week_hold.pf_hold_id) }
      let!(:tt_player) { create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 2) }
      let(:params) { nil }

      it '今週開催の情報（月曜更新）が取得される' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(this_week_hold.promoter_year)
        expect(json['data']['season']).to eq(this_week_hold.period)
        expect(json['data']['round_code']).to eq(this_week_hold.round)
        expect(json['data']['hold_id']).to eq(this_week_hold.id)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(this_week_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(this_week_hold.hold_days)
        expect(json['data']['tt_movie_yt_id']).to eq(this_week_hold.tt_movie_yt_id)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(this_week_hold.time_trial_result.time_trial_players.first.total_time)
        expect(json['data']['tt_result_list'][0]['rank']).to eq(this_week_hold.time_trial_result.time_trial_players.first.ranking)
        expect(json['data']['tt_result_list'][0]['pf_250_regist_id']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).pf_250_regist_id)
        expect(json['data']['tt_result_list'][0]['country_code']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).player_original_info.free2)
        expect(json['data']['tt_result_list'][0]['first_name_jp']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).player_original_info.first_name_jp)
        expect(json['data']['tt_result_list'][0]['last_name_jp']).to eq(Player.find_by(pf_player_id: tt_player.pf_player_id).player_original_info.last_name_jp)
      end
    end

    context 'tt_playerが複数ある場合' do
      let(:this_week_hold) { create(:hold, period: 'spring', round: 1, first_day: Time.zone.today) }
      let(:tt_result) { create(:time_trial_result, hold: this_week_hold, pf_hold_id: this_week_hold.pf_hold_id) }
      let(:params) { nil }

      it 'rank順にソートして取得される' do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 12)
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 4)
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 23.45, ranking: 13)
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['rank']).to eq 4
        expect(json['data']['tt_result_list'][1]['rank']).to eq 12
        expect(json['data']['tt_result_list'][2]['rank']).to eq 13
      end
    end

    context 'promoter_yearが指定されていて、season, round_codeが指定されていない場合' do
      let(:params) { { promoter_year: 2021 } }

      it 'bad_requestエラーが返る' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end

    context '開催情報はあるが、タイムトライアル結果がない場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, hold_status: 1) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      it '開催情報が出力される' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(spring_hold.promoter_year)
        expect(json['data']['season']).to eq(spring_hold.period)
        expect(json['data']['round_code']).to eq(spring_hold.round)
        expect(json['data']['hold_id']).to eq(spring_hold.id)
        expect(json['data']['hold_status']).to eq(1)
        expect(json['data']['first_day']).to eq(spring_hold.first_day.strftime('%Y-%m-%d'))
        expect(json['data']['hold_days']).to eq(spring_hold.hold_days)
        expect(json['data']['tt_movie_yt_id']).to eq(spring_hold.tt_movie_yt_id)
      end

      it '空のtt_result_listが返る' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list']).to eq([])
      end
    end

    context 'paramsを指定しない場合' do
      let(:params) { nil }

      context '今週の開催のpromoter_year, series, round_codeがない場合、' do
        before do
          create(:hold, promoter_year: nil, period: 'spring', round: 1, first_day: Time.zone.today)
        end

        it 'nilが返る' do
          get_time_trial_results_revision
          json = JSON.parse(response.body)
          expect(json['data']).to eq(nil)
        end
      end

      context 'periodがない場合、' do
        before do
          create(:hold, promoter_year: 2021, period: nil, round: 1, first_day: Time.zone.today)
        end

        it 'nilが返る' do
          get_time_trial_results_revision
          json = JSON.parse(response.body)
          expect(json['data']).to eq(nil)
        end
      end

      context 'round_codeがない場合、' do
        before do
          create(:hold, promoter_year: 2021, period: 'spring', round: nil, first_day: Time.zone.today)
        end

        it 'nilが返る' do
          get_time_trial_results_revision
          json = JSON.parse(response.body)
          expect(json['data']).to eq(nil)
        end
      end
    end

    context 'total_timeが99.9999の場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 99.9999)
      end

      it 'total_timeがnilで返ってくること' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(nil)
      end
    end

    context 'total_timeが99.999の場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: 99.999)
      end

      it 'total_timeがnilで返ってくること' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(nil)
      end
    end

    context 'total_timeがnilの場合' do
      let!(:spring_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1) }
      let(:tt_result) { create(:time_trial_result, hold: spring_hold, pf_hold_id: spring_hold.pf_hold_id) }
      let(:params) do
        {
          promoter_year: spring_hold.promoter_year,
          season: spring_hold.period,
          round_code: spring_hold.round
        }
      end

      before do
        create(:time_trial_player, time_trial_result: tt_result, pf_player_id: player.pf_player_id, total_time: nil)
      end

      it 'total_timeがnilで返ってくること' do
        get_time_trial_results_revision
        json = JSON.parse(response.body)
        expect(json['data']['tt_result_list'][0]['total_time']).to eq(nil)
      end
    end
  end

  describe 'GET /races' do
    subject(:get_races) { get v1_mt_datas_races_url, params: params }

    let(:params) { { hold_daily_schedule_id_list: [hold_daily.hold_daily_schedules.first.id] } }
    let(:hold) { create(:hold, promoter_year: Time.zone.now.year, period: 1, round: 1, hold_status: 1) }
    let(:hold_daily) { create(:hold_daily, :with_final_race, hold: hold) }
    let!(:hold_daily_schedule) { hold_daily.hold_daily_schedules.first }

    before do
      hold_daily_schedule.races.update(details_code: 'F1')
      create(:race_result, entries_id: '111111', race_detail: hold_daily_schedule.races.first.race_detail)
    end

    context '取得成功' do
      it 'レスポンスパラメータの確認' do
        race_pf_player_id = hold_daily_schedule.races.first.race_detail.race_players.first.pf_player_id
        race_pf_250_regist_id = Player.find_by(pf_player_id: race_pf_player_id).pf_250_regist_id
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['promoter_year']).to eq(hold.promoter_year)
        expect(json['data'][0]['season']).to eq(hold.period)
        expect(json['data'][0]['round_code']).to eq(hold.round)
        expect(json['data'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule.id)
        expect(json['data'][0]['race_list'][0]['id']).to eq(hold_daily_schedule.races.first.id)
        expect(json['data'][0]['race_list'][0]['race_no']).to eq(hold_daily_schedule.races.first.race_no)
        expect(json['data'][0]['race_list'][0]['event_date']).to eq(hold_daily.event_date.strftime('%Y-%m-%d'))
        expect(json['data'][0]['race_list'][0]['day_night']).to eq(hold_daily_schedule.daily_no_before_type_cast)
        expect(json['data'][0]['race_list'][0]['post_time']).to eq(time_format(hold_daily_schedule.races.first.post_time))
        expect(json['data'][0]['race_list'][0]['name']).to eq(hold_daily_schedule.races.first.event_code)
        expect(json['data'][0]['race_list'][0]['detail']).to eq(hold_daily_schedule.races.first.details_code)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(3)
        expect(json['data'][0]['race_list'][0]['free_text']).to eq hold_daily_schedule.races.first.free_text
        expect(json['data'][0]['race_list'][0]['player_list'][0]['id']).to eq(race_pf_250_regist_id)
        expect(json['data'][0]['race_list'][0]['player_list'].size).to eq(hold_daily_schedule.races.first.race_detail.race_players.size)
      end
    end

    context '出走表がなく、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは2になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.destroy
        hold.update(hold_status: [*2..9].sample)
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(2)
      end
    end

    context '出走表がなく、開催が終了していない場合（hold_statusが0、1の場合）、対象のrace_listのcancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.destroy
        hold.update(hold_status: [0, 1].sample)
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context 'race_statusが0またはnilで、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: ['0', nil].sample)
        hold.update(hold_status: [*2..9].sample)
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context 'race_statusが0またはnilで、開催が終了していない場合（hold_statusが0、1の場合））、対象のrace_listのcancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: ['0', nil].sample)
        hold.update(hold_status: [0, 1].sample)
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context 'race_statusが0,10,15,nil以外の場合、cancel_statusは2になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: '20')
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(2)
      end
    end

    context 'race_statusが0,10,15,nilの場合、cancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: ['0', '10', '15', nil].sample)
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context '出走表がない場合、対象のrace_listのrace_statusは1になること' do
      it 'レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.destroy
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
      end
    end

    context '出走選手がない場合、対象のrace_listのrace_statusは1になること' do
      it 'レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.race_players.destroy_all
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
      end
    end

    context '出走表、出走選手はあるが、レース結果がない場合、対象のrace_listのrace_statusは2になること' do
      it 'レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.race_result.destroy
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(2)
      end
    end

    context 'params指定しない場合' do
      let(:params) { nil }
      let(:hold_daily) { create(:hold_daily, :with_final_race, event_date: Time.zone.now + 1.day, hold: hold) }

      it '開催前のレースがある場合、リクエスト日以降で開始前のレースを含む最初の販売情報をベースにして取得する' do
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule.id)
      end

      it '開催前のレースがない場合、最後の販売情報を取得する' do
        create(:race_result, race_detail: hold_daily_schedule.races.first.race_detail)
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule.id)
      end
    end

    context 'params指定無しで、開催前のレースがある場合' do
      let(:params) { nil }
      let(:hold_daily) { create(:hold_daily, :with_final_race, event_date: Time.zone.now + 1.day, hold: hold) }

      it 'promoter_yearがnilの場合、取得できないこと' do
        hold.update(promoter_year: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'roundがnilの場合、取得できないこと' do
        hold.update(round: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'periodがnilの場合、取得できないこと' do
        hold.update(period: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'details_codeがnilの場合、取得できないこと' do
        hold_daily_schedule.races.update(details_code: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end
    end

    context 'params指定無しで、開催前のレースがない場合' do
      let(:params) { nil }
      let(:hold_daily) { create(:hold_daily, :with_final_race, event_date: Time.zone.now + 1.day, hold: hold) }
      let(:race_result) { create(:race_result, race_detail: hold_daily_schedule.races.first.race_detail) }

      it 'promoter_yearがnilの場合、取得できないこと' do
        race_result
        hold.update(promoter_year: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'roundがnilの場合、取得できないこと' do
        race_result
        hold.update(round: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'periodがnilの場合、取得できないこと' do
        race_result
        hold.update(period: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'details_codeがnilの場合、取得できないこと' do
        race_result
        hold_daily_schedule.races.update(details_code: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end
    end

    context '出走表あるいは出走表に選手が入っていない場合' do
      let(:hold_daily_3) { create(:hold_daily, hold: hold) }
      let(:hold_daily_schedule_3) { create(:hold_daily_schedule, hold_daily: hold_daily_3) }
      let!(:race) { create(:race, hold_daily_schedule: hold_daily_schedule_3, details_code: 'F1') }
      let(:params) { { hold_daily_schedule_id_list: [hold_daily_schedule_3.id] } }

      context '出走表がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.destroy
          get_races
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走選手がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.race_players.destroy_all
          get_races
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走表、出走選手はあるが、レース結果がない場合、対象のrace_listのrace_statusは2になること' do
        let!(:race_detail) { create(:race_detail, race: race) }

        it 'レスポンスパラメータの確認' do
          create(:race_player, race_detail: race_detail)
          get_races
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['race_status']).to eq(2)
        end
      end
    end

    context '必須のパラメータがない場合' do
      it 'promoter_yearがnilの場合、取得できないこと' do
        hold.update(promoter_year: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'roundがnilの場合、取得できないこと' do
        hold.update(round: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'periodがnilの場合、取得できないこと' do
        hold.update(period: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'details_codeがnilの場合、取得できないこと' do
        hold_daily_schedule.races.update(details_code: nil)
        get_races
        expect(JSON.parse(response.body)['data']).to be_blank
      end
    end

    context 'event_codeがWの場合' do
      it 'raceのevent_codeがWの場合、nameでTを返すこと' do
        hold_daily_schedule.races.first.update(event_code: 'W')
        get_races
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['name']).to eq('T')
      end
    end
  end

  describe 'GET /hold_daily_schedules' do
    subject(:get_hold_daily_schedules) { get v1_mt_datas_hold_daily_schedules_url, params: params }

    let!(:spring_hold) { create(:hold, promoter_year: Time.zone.now.year, period: 'spring', round: 1, hold_name_jp: 'spring_test1') }
    let!(:summer_hold) { create(:hold, promoter_year: Time.zone.now.year, period: 'summer', round: 1, hold_name_jp: 'summer_test1') }
    let!(:summer_hold2) { create(:hold, promoter_year: Time.zone.now.year, period: 'summer', round: 2, hold_name_jp: 'summer_test2') }
    let!(:spring_hold_daily) { create(:hold_daily, hold: spring_hold, daily_status: :before_held) }
    let!(:spring_hold_daily2) { create(:hold_daily, hold: spring_hold, daily_status: :before_held, event_date: Time.zone.parse('20210101')) }
    let!(:summer_hold_daily) { create(:hold_daily, hold: summer_hold, daily_status: :being_held) }
    let!(:summer_hold_daily2) { create(:hold_daily, hold: summer_hold2, daily_status: :being_held) }
    let!(:spring_hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: spring_hold_daily) }
    let!(:summer_hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: summer_hold_daily) }
    let!(:summer_hold_daily_schedule_nil) { create(:hold_daily_schedule, hold_daily: summer_hold_daily2) }
    let!(:spring_hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily: spring_hold_daily, daily_no: 1) }
    let!(:spring_hold_daily_schedule3) { create(:hold_daily_schedule, hold_daily: spring_hold_daily2, daily_no: 1) }
    let!(:spring_hold_daily_schedule4) { create(:hold_daily_schedule, hold_daily: spring_hold_daily2, daily_no: 0) }
    let!(:spring_hold_daily_schedule_race) { create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST[0], hold_daily_schedule: spring_hold_daily_schedule) }

    before do
      create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST[1], hold_daily_schedule: spring_hold_daily_schedule)
      create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST[3], hold_daily_schedule: summer_hold_daily_schedule)
      create(:race, event_code: nil, hold_daily_schedule: summer_hold_daily_schedule)
      create(:race, event_code: nil, hold_daily_schedule: summer_hold_daily_schedule_nil)
      create(:race_detail, race: spring_hold_daily_schedule_race)
    end

    context 'raceのevent_codeの値が"W","X","Y"（順位決定戦C,D,E）の場合、' do
      let!(:hold) { create(:hold, promoter_year: 1999, period: 'spring', round: 1, hold_name_jp: 'test') }
      let!(:hold_daily) { create(:hold_daily, hold: hold, daily_status: :before_held) }
      let!(:hold_daily_schedule_w) { create(:hold_daily_schedule, hold_daily: hold_daily) }
      let!(:hold_daily_schedule_x) { create(:hold_daily_schedule, hold_daily: hold_daily) }
      let!(:hold_daily_schedule_y) { create(:hold_daily_schedule, hold_daily: hold_daily) }

      let(:params) { { promoter_year: hold.promoter_year, season: hold.period, round_code: hold.round } }

      before do
        create(:race, event_code: 'W', hold_daily_schedule: hold_daily_schedule_w)
        create(:race, event_code: 'X', hold_daily_schedule: hold_daily_schedule_x)
        create(:race, event_code: 'Y', hold_daily_schedule: hold_daily_schedule_y)
      end

      it 'event_codeは"T"を出力' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['event_code']).to eq('T')
        expect(json['data']['hold_daily_schedule_list'][1]['event_code']).to eq('T')
        expect(json['data']['hold_daily_schedule_list'][2]['event_code']).to eq('T')
      end
    end

    context 'リクエストパラメータにpromoter_year, season, round_codeを指定した場合、' do
      let(:params) { { promoter_year: Time.zone.now.year, season: 'spring', round_code: 1 } }

      it 'レスポンスパラメータの確認' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['id']).to eq(spring_hold_daily_schedule.id)
        expect(json['data']['hold_daily_schedule_list'][0]['hold_schedule_status']).to eq(1)
        expect(json['data']['hold_daily_schedule_list'][0]['promoter_year']).to eq(spring_hold.promoter_year)
        expect(json['data']['hold_daily_schedule_list'][0]['season']).to eq(spring_hold.period)
        expect(json['data']['hold_daily_schedule_list'][0]['round_code']).to eq(spring_hold.round)
        expect(json['data']['hold_daily_schedule_list'][0]['event_date'].to_date).to eq(spring_hold_daily_schedule.event_date)
        expect(json['data']['hold_daily_schedule_list'][0]['day_night']).to eq(spring_hold_daily_schedule.daily_no_before_type_cast)
      end

      it 'hold_daily_schedule_listが日付順で、デイ・ナイト順にソートして返す' do
        create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST.sample, hold_daily_schedule: spring_hold_daily_schedule2)
        create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST.sample, hold_daily_schedule: spring_hold_daily_schedule3)
        create(:race, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST.sample, hold_daily_schedule: spring_hold_daily_schedule4)

        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['event_date']).to be <= json['data']['hold_daily_schedule_list'][1]['event_date']
        expect(json['data']['hold_daily_schedule_list'][1]['event_date']).to be <= json['data']['hold_daily_schedule_list'][2]['event_date']
        expect(json['data']['hold_daily_schedule_list'][2]['event_date']).to be <= json['data']['hold_daily_schedule_list'][3]['event_date']
        expect(json['data']['hold_daily_schedule_list'][0]['day_night']).to be <= json['data']['hold_daily_schedule_list'][1]['day_night']
        expect(json['data']['hold_daily_schedule_list'][2]['day_night']).to be <= json['data']['hold_daily_schedule_list'][3]['day_night']
      end

      context 'daily_statusが 3, 4, 7, 8, 9の場合、' do
        before do
          spring_hold_daily.update(daily_status: [3, 4, 7, 8, 9].sample)
        end

        it 'hold_schedule_statusが2を返すこと' do
          get_hold_daily_schedules
          json = JSON.parse(response.body)
          expect(json['data']['hold_daily_schedule_list'][0]['hold_schedule_status']).to eq(2)
        end
      end

      context 'daily_statusが 3, 4, 7, 8, 9以外の場合、' do
        before do
          spring_hold_daily.update(daily_status: 0)
        end

        it 'hold_schedule_statusが1を返すこと' do
          get_hold_daily_schedules
          json = JSON.parse(response.body)
          expect(json['data']['hold_daily_schedule_list'][0]['hold_schedule_status']).to eq(1)
        end
      end

      context 'hold_statusが2(開催終了)で、hold_dailyに紐づくrace_detailsが存在しない場合、' do
        before do
          spring_hold.update(hold_status: 2)
          spring_hold_daily_schedule_race.race_detail.destroy
          spring_hold_daily.update(daily_status: 0)
        end

        it 'hold_schedule_statusが2を返すこと' do
          get_hold_daily_schedules
          json = JSON.parse(response.body)
          expect(json['data']['hold_daily_schedule_list'][0]['hold_schedule_status']).to eq(2)
        end
      end

      context 'hold_statusが2(開催終了)以外で、hold_dailyに紐づくrace_detailsが存在しない場合、' do
        before do
          spring_hold.update(hold_status: 0)
          spring_hold_daily_schedule_race.race_detail.destroy
          spring_hold_daily.update(daily_status: 0)
        end

        it 'hold_schedule_statusが1を返すこと' do
          get_hold_daily_schedules
          json = JSON.parse(response.body)
          expect(json['data']['hold_daily_schedule_list'][0]['hold_schedule_status']).to eq(1)
        end
      end

      context 'hold_statusが2(開催終了)で、hold_dailyに紐づくrace_detailsが存在する場合、' do
        before do
          spring_hold.update(hold_status: 2)
          spring_hold_daily.update(daily_status: 0)
        end

        it 'hold_schedule_statusが1を返すこと' do
          get_hold_daily_schedules
          json = JSON.parse(response.body)
          expect(json['data']['hold_daily_schedule_list'][0]['hold_schedule_status']).to eq(1)
        end
      end
    end

    context 'リクエストパラメータにpromoter_year指定しない場合、' do
      let(:params) { nil }

      let!(:hold_starts_tomorror) { create(:hold, first_day: Time.zone.today.tomorrow) }
      let!(:hold_started_yesterday) { create(:hold, first_day: Time.zone.today.yesterday) }
      let!(:hold_started_2_days_ago) { create(:hold, first_day: Time.zone.today.ago(2.days)) }

      let!(:hold_starts_tomorror_hold_daily) { create(:hold_daily, hold: hold_starts_tomorror, event_date: Time.zone.today.tomorrow) }
      let!(:hold_started_yesterday_hold_daily) { create(:hold_daily, hold: hold_started_yesterday, event_date: Time.zone.today.yesterday) }
      let!(:hold_started_2_days_ago_hold_daily) { create(:hold_daily, hold: hold_started_2_days_ago, event_date: Time.zone.today.ago(2.days)) }

      let!(:hold_starts_tomorror_hold_daily_schedule_pm) { create(:hold_daily_schedule, :with_race, hold_daily: hold_starts_tomorror_hold_daily, daily_no: 1) }
      let!(:hold_starts_tomorror_hold_daily_schedule_am) { create(:hold_daily_schedule, :with_race, hold_daily: hold_starts_tomorror_hold_daily, daily_no: 0) }
      let!(:hold_started_yesterday_hold_daily_schedule_am) { create(:hold_daily_schedule, :with_race, hold_daily: hold_started_yesterday_hold_daily, daily_no: 0) }
      let!(:hold_started_2_days_ago_hold_daily_schedule) { create(:hold_daily_schedule, :with_race, hold_daily: hold_started_2_days_ago_hold_daily) }

      let!(:hold_starts_tomorror_hold_name_jp_nil) { create(:hold, first_day: Time.zone.today.tomorrow, hold_name_jp: nil) }
      let!(:hold_starts_tomorror_period_nil) { create(:hold, first_day: Time.zone.today.tomorrow, period: nil) }
      let!(:hold_starts_tomorror_round_nil) { create(:hold, first_day: Time.zone.today.tomorrow, round: nil) }
      let!(:hold_daily_hold_name_jp_nil) { create(:hold_daily, hold: hold_starts_tomorror_hold_name_jp_nil, event_date: Time.zone.today.tomorrow) }
      let!(:hold_daily_period_nil) { create(:hold_daily, hold: hold_starts_tomorror_period_nil, event_date: Time.zone.today.tomorrow) }
      let!(:hold_daily_round_nil) { create(:hold_daily, hold: hold_starts_tomorror_round_nil, event_date: Time.zone.today.tomorrow) }
      let!(:hold_daily_schedule_hold_name_jp_nil) { create(:hold_daily_schedule, :with_race, hold_daily: hold_daily_hold_name_jp_nil) }
      let!(:hold_daily_schedule_period_nil) { create(:hold_daily_schedule, :with_race, hold_daily: hold_daily_period_nil) }
      let!(:hold_daily_schedule_round_nil) { create(:hold_daily_schedule, :with_race, hold_daily: hold_daily_round_nil) }

      before do
        create(:hold_daily_schedule, hold_daily: hold_starts_tomorror_hold_daily)
        create(:hold_daily_schedule, :with_race, hold_daily: hold_started_yesterday_hold_daily, daily_no: 1)
      end

      it '必須項目（hold.period, hold.round）がnilのデータを出力しない' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'].map { |hold_daily_schedule| hold_daily_schedule['id'] })
          .not_to include(hold_daily_schedule_period_nil.id, hold_daily_schedule_round_nil.id)
      end

      it 'hold.hold_name_jpがnilのデータを出力する' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'].map { |hold_daily_schedule| hold_daily_schedule['id'] })
          .to include(hold_daily_schedule_hold_name_jp_nil.id)
      end

      it 'first_dayが現在時刻より2日前の開催が出力されないこと' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'].map { |hold_daily_schedule| hold_daily_schedule['id'] })
          .not_to include(hold_started_2_days_ago_hold_daily_schedule.id)
      end

      it 'first_dayが現在時刻より1日前の開催が出力されること' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'].map { |hold_daily_schedule| hold_daily_schedule['id'] })
          .to include(hold_started_yesterday_hold_daily_schedule_am.id)
      end

      it 'first_dayが明日の開催が出力されること' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'].map { |hold_daily_schedule| hold_daily_schedule['id'] })
          .to include(hold_starts_tomorror_hold_daily_schedule_am.id, hold_starts_tomorror_hold_daily_schedule_pm.id)
      end

      it 'hold_daily_schedule_listはevent_dateの昇順でソートして返す' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['event_date']).to eq(hold_started_yesterday_hold_daily.event_date.strftime('%Y-%m-%d'))
        expect(json['data']['hold_daily_schedule_list'][1]['event_date']).to eq(hold_started_yesterday_hold_daily.event_date.strftime('%Y-%m-%d'))
        expect(json['data']['hold_daily_schedule_list'][2]['event_date']).to eq(hold_starts_tomorror_hold_daily.event_date.strftime('%Y-%m-%d'))
        expect(json['data']['hold_daily_schedule_list'][3]['event_date']).to eq(hold_starts_tomorror_hold_daily.event_date.strftime('%Y-%m-%d'))
      end

      it 'hold_daily_schedule_listはdaily_noはデイ・ナイト順にソートして返す' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['day_night']).to eq(0)
        expect(json['data']['hold_daily_schedule_list'][1]['day_night']).to eq(1)
      end

      it '優先度の一番高いレースのevent_codeを出力する' do
        create(:race, hold_daily_schedule: hold_started_yesterday_hold_daily_schedule_am, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST.first)
        create(:race, hold_daily_schedule: hold_started_yesterday_hold_daily_schedule_am, event_code: Constants::PRIORITIZED_EVENT_CODE_LIST.last)

        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['event_code']).to eq(Constants::PRIORITIZED_EVENT_CODE_LIST.first)
      end
    end

    context '優先順位のリストに載っているレースがない場合' do
      before do
        spring_hold_daily_schedule.races.each do |race|
          race.event_code = 'not_in_priority_code_list'
          race.save
        end
      end

      let(:params) do
        { promoter_year: spring_hold_daily_schedule.promoter_year,
          season: spring_hold_daily_schedule.period,
          round_code: spring_hold_daily_schedule.round }
      end

      it 'hold_daily_scheduleの先頭レースのevent_codeを返す' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['data']['hold_daily_schedule_list'][0]['event_code']).to eq(spring_hold_daily_schedule.races.first.event_code)
      end
    end

    context 'リクエストパラメータにpromoter_year指定して、season, round_codeを指定しない場合、' do
      let(:params) { { promoter_year: Time.zone.now.year } }

      it 'エラーメッセージが返る' do
        get_hold_daily_schedules
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('promoter_yearを指定する場合は、seasonとround_codeを指定してください')
      end
    end
  end

  describe 'GET /player_detail' do
    subject(:player_detail_key) { %w[id last_name_jp first_name_jp last_name_en first_name_en birthday height weight country_code catchphrase speed stamina power technique mental evaluation round_best year_best major_title pist6_title winner_rate first_place_count second_place_count first_count round_result_list] }

    let(:get_player_detail) { get v1_mt_datas_player_detail_url, params: { sort_key: sort_key, limit: limit, offset: offset, players: players, filter_key: filter_key, filter_value: filter_value } }
    let!(:hold) { create(:hold, hold_status: :finished_held, first_day: '20210901') }
    let!(:hold_2) { create(:hold, hold_status: :finished_held, first_day: '20210902') }

    let(:player) { create(:player, pf_player_id: 999, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join) }
    let(:player_2) { create(:player, pf_player_id: 998, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join) }

    let!(:time_trial_result) { create(:time_trial_result, hold_id: hold.id) }
    let!(:time_trial_result_2) { create(:time_trial_result, hold_id: hold_2.id) }

    let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
    let!(:hold_player_2) { create(:hold_player, hold: hold, player: player_2) }

    let!(:hold_daily) { create(:hold_daily, hold: hold, hold_daily: 2) }
    let!(:hold_daily_dummy) { create(:hold_daily, hold: hold, hold_daily: 1) }
    let!(:hold_daily_2) { create(:hold_daily, hold: hold_2) }

    let!(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily_id: hold_daily.id) }
    let!(:hold_daily_schedule_dummy) { create(:hold_daily_schedule, hold_daily_id: hold_daily_dummy.id) }
    let!(:hold_daily_schedule_2) { create(:hold_daily_schedule, hold_daily_id: hold_daily_2.id) }

    let!(:race1) { create(:race, hold_daily_schedule_id: hold_daily_schedule.id, race_no: 1, event_code: 'aa', details_code: 'details1') }
    let!(:race2) { create(:race, hold_daily_schedule_id: hold_daily_schedule.id, race_no: 2, event_code: 'bb', details_code: 'details2') }
    let!(:race3) { create(:race, hold_daily_schedule_id: hold_daily_schedule.id, race_no: 3, event_code: 'cc', details_code: 'details3') }

    let!(:race_dummy) { create(:race, hold_daily_schedule_id: hold_daily_schedule_dummy.id, race_no: 100, event_code: 'dummy_event', details_code: 'dummy_details') }

    let!(:race_2_1) { create(:race, hold_daily_schedule_id: hold_daily_schedule_2.id, race_no: 11, event_code: 'aaa', details_code: 'details2_1', program_no: 3) }
    let!(:race_2_2) { create(:race, hold_daily_schedule_id: hold_daily_schedule_2.id, race_no: 12, event_code: 'bbb', details_code: 'details2_2', program_no: 4) }
    let!(:race_2_3) { create(:race, hold_daily_schedule_id: hold_daily_schedule_2.id, race_no: 13, event_code: 'ccc', details_code: 'details2_3', program_no: 5) }
    let!(:race_2_4) { create(:race, hold_daily_schedule_id: hold_daily_schedule_2.id, race_no: 13, event_code: 'ddd', details_code: 'details2_4', program_no: 2) }
    let!(:race_2_5) { create(:race, hold_daily_schedule_id: hold_daily_schedule_2.id, race_no: 13, event_code: 'eee', details_code: 'details2_5', program_no: 1) }

    let!(:race_detail1) { create(:race_detail, race_id: race1.id, hold_daily: 3, hold_day: '20210101') }
    let!(:race_detail2) { create(:race_detail, race_id: race2.id, hold_daily: 2, hold_day: '20210120') }
    let!(:race_detail3) { create(:race_detail, race_id: race3.id, hold_daily: 1, hold_day: '20210130') }

    let!(:race_detail_dummy) { create(:race_detail, race_id: race_dummy.id) }

    let!(:race_detail_2_1) { create(:race_detail, race_id: race_2_1.id, hold_daily: 1, hold_day: '20210201') }
    let!(:race_detail_2_2) { create(:race_detail, race_id: race_2_2.id, hold_daily: 2, hold_day: '20210220') }
    let!(:race_detail_2_3) { create(:race_detail, race_id: race_2_3.id, hold_daily: 3, hold_day: '20210228') }
    let!(:race_detail_2_4) { create(:race_detail, race_id: race_2_4.id, hold_daily: 4, hold_day: '20210228') }
    let!(:race_detail_2_5) { create(:race_detail, race_id: race_2_5.id, hold_daily: 5, hold_day: '20210228') }

    let!(:race_result1) { create(:race_result, race_detail_id: race_detail1.id) }
    let!(:race_result2) { create(:race_result, race_detail_id: race_detail2.id) }
    let!(:race_result3) { create(:race_result, race_detail_id: race_detail3.id) }

    let!(:race_result_dummy) { create(:race_result, race_detail_id: race_detail_dummy.id) }

    let!(:race_result_2_1) { create(:race_result, race_detail_id: race_detail_2_1.id) }
    let!(:race_result_2_2) { create(:race_result, race_detail_id: race_detail_2_2.id) }
    let!(:race_result_2_3) { create(:race_result, race_detail_id: race_detail_2_3.id) }
    let!(:race_result_2_4) { create(:race_result, race_detail_id: race_detail_2_4.id) }
    let!(:race_result_2_5) { create(:race_result, race_detail_id: race_detail_2_5.id) }

    let!(:time_trial_player) { create(:time_trial_player, time_trial_result_id: time_trial_result.id, pf_player_id: player.pf_player_id, total_time: 1.5, ranking: 1) }
    let!(:time_trial_player1_2) { create(:time_trial_player, time_trial_result_id: time_trial_result_2.id, pf_player_id: player.pf_player_id, total_time: 1.5, ranking: 1) }
    let!(:time_trial_player2) { create(:time_trial_player, time_trial_result_id: time_trial_result.id, pf_player_id: player_2.pf_player_id, total_time: 2.5, ranking: 2) }

    let!(:race_result_player_race_2_1) { create(:race_result_player, race_result_id: race_result_2_3.id, pf_player_id: player.pf_player_id, rank: 5) }
    let!(:race_result_player_race3) { create(:race_result_player, race_result_id: race_result3.id, pf_player_id: player.pf_player_id, rank: 3) }
    let!(:race_result_player2_race2) { create(:race_result_player, race_result_id: race_result2.id, pf_player_id: player_2.pf_player_id, rank: 8) }

    before do
      create_list(:hold, 28, :with_player_detail)
      create(:mediated_player, hold_player: hold_player, pf_player_id: player.pf_player_id)
      create(:mediated_player, hold_player: hold_player_2, pf_player_id: player.pf_player_id)

      create(:player_original_info, player: player, pf_250_regist_id: 20, speed: 5, stamina: 1, power: 2, technique: 3, mental: 4, evaluation: 99, round_best: 'mm:ss.MMMM', year_best: 'mm:ss.MMMM',
                                    major_title: 'test', pist6_title: 'bb', last_name_en: player.name_en, first_name_en: player.name_en)
      create(:player_original_info, player: player_2, pf_250_regist_id: 10, speed: 6, stamina: 2, power: 3, technique: 4, mental: 5, evaluation: 6,
                                    last_name_en: player_2.name_en, first_name_en: player_2.name_en)

      create(:race_result_player, race_result_id: race_result2.id, pf_player_id: player.pf_player_id, rank: 0)
      create(:race_result_player, race_result_id: race_result_2_1.id, pf_player_id: player.pf_player_id, rank: 8)
      create(:race_result_player, race_result_id: race_result_2_2.id, pf_player_id: player.pf_player_id, rank: 9)
      create(:race_result_player, race_result_id: race_result_2_4.id, pf_player_id: player.pf_player_id, rank: 1)
      create(:race_result_player, race_result_id: race_result_2_5.id, pf_player_id: player.pf_player_id, rank: 2)
      create(:race_result_player, race_result_id: race_result3.id, pf_player_id: player_2.pf_player_id)
      create(:race_result_player, race_result_id: race_result1.id, pf_player_id: player.pf_player_id, rank: 1)
      create(:race_result_player, race_result_id: race_result1.id, pf_player_id: player_2.pf_player_id, rank: 4)

      create(:race_result_player, race_result_id: race_result_dummy.id, pf_player_id: player.pf_player_id, rank: 100)

      create(:player_result, player_id: player.id, pf_player_id: player.pf_player_id, winner_rate: 3.12, first_count: 2, first_place_count: 1, second_place_count: 3)
      create(:player_result, player_id: player_2.id, pf_player_id: player_2.pf_player_id, winner_rate: 4.12, first_count: 5, first_place_count: 6, second_place_count: 7)
    end

    context 'playersリストがない且つlimitがない場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it '正しいフォーマットで、最大件数２０件でレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['total']).to eq(30)
        expect(json['data']['sort_key']).to eq(sort_key)
        expect(json['data']['limit']).to eq(limit)
        expect(json['data']['offset']).to eq(offset)
        expect(json['data']['player_list'].count).to eq(20)
        json['data']['player_list'].all? { |hash| expect(hash.keys).to match_array(player_detail_key) }
      end
    end

    context 'playersリストがない且つlimitがない且つsort_key(alphabet)がある場合' do
      let(:sort_key) { 'alphabet' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it 'sort_key(name_en)でソートされて、最大件数２０件でレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['total']).to eq(30)
        expect(json['data']['sort_key']).to eq(sort_key)
        expect(json['data']['limit']).to eq(limit)
        expect(json['data']['offset']).to eq(offset)
        expect(json['data']['player_list'].count).to eq(20)
        json['data']['player_list'].all? { |hash| expect(hash.keys).to match_array(player_detail_key) }
        expect(json['data']['player_list'][0]['last_name_en']).to be <= json['data']['player_list'][1]['last_name_en']
        expect(json['data']['player_list'][1]['last_name_en']).to be <= json['data']['player_list'][2]['last_name_en']
      end
    end

    context 'playersリストがない且つlimitがない且つsort_key(speed)がある場合' do
      let(:sort_key) { 'speed' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it 'sort_key(speed)でソートされて、最大件数２０件でレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['total']).to eq(30)
        expect(json['data']['sort_key']).to eq(sort_key)
        expect(json['data']['limit']).to eq(limit)
        expect(json['data']['offset']).to eq(offset)
        expect(json['data']['player_list'].count).to eq(20)
        json['data']['player_list'].all? { |hash| expect(hash.keys).to match_array(player_detail_key) }
        expect(json['data']['player_list'][2]['speed']).to be <= json['data']['player_list'][1]['speed']
        expect(json['data']['player_list'][1]['speed']).to be <= json['data']['player_list'][0]['speed']
      end
    end

    context 'playersリストがない且つlimitが10且つoffsetがある場合' do
      let(:sort_key) { nil }
      let(:limit) { 10 }
      let(:offset) { 5 }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it 'offset処理されて、１０件でレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['total']).to eq(30)
        expect(json['data']['sort_key']).to eq(sort_key)
        expect(json['data']['limit']).to eq(limit)
        expect(json['data']['offset']).to eq(offset)
        expect(json['data']['player_list'].count).to eq(10)
        json['data']['player_list'].all? { |hash| expect(hash.keys).to match_array(player_detail_key) }
        expect(json['data']['player_list'][0]['id']).to eq(Player.joins(:player_original_info).order('char_length(pf_250_regist_id)', 'pf_250_regist_id').offset(5).first.pf_250_regist_id)
      end
    end

    context 'playersリストがある場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { [player.pf_250_regist_id, player_2.pf_250_regist_id] }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it 'playersリストの内容でレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['total']).to eq(2)
        expect(json['data']['sort_key']).to eq(sort_key)
        expect(json['data']['limit']).to eq(limit)
        expect(json['data']['offset']).to eq(offset)
        expect(json['data']['player_list'].count).to eq(2)
        json['data']['player_list'].all? { |hash| expect(hash.keys).to match_array(player_detail_key) }
        expect(json['data']['player_list'][0]['id']).to eq(player_2.pf_250_regist_id)
        expect(json['data']['player_list'][0]['last_name_jp']).to eq(player_2.last_name_jp)
        expect(json['data']['player_list'][0]['last_name_en']).to eq(player_2.last_name_en)
        expect(json['data']['player_list'][0]['height']).to eq(player_2.player_original_info.free4&.to_f)
        expect(json['data']['player_list'][0]['weight']).to eq(player_2.player_original_info.free5&.to_f)
        expect(json['data']['player_list'][0]['country_code']).to eq(player_2.player_original_info.free2)
        expect(json['data']['player_list'][0]['catchphrase']).to eq(player_2.nickname)
        expect(json['data']['player_list'][0]['speed']).to eq(player_2.player_original_info.speed)
        expect(json['data']['player_list'][0]['stamina']).to eq(player_2.player_original_info.stamina)
        expect(json['data']['player_list'][0]['power']).to eq(player_2.player_original_info.power)
        expect(json['data']['player_list'][0]['technique']).to eq(player_2.player_original_info.technique)
        expect(json['data']['player_list'][0]['mental']).to eq(player_2.player_original_info.mental)
        expect(json['data']['player_list'][0]['evaluation']).to eq('C')
        expect(json['data']['player_list'][0]['round_best']).to eq(player_2.player_original_info.round_best)
        expect(json['data']['player_list'][0]['year_best']).to eq(player_2.player_original_info.year_best)
        expect(json['data']['player_list'][0]['major_title']).to eq(player_2.player_original_info.major_title)
        expect(json['data']['player_list'][0]['pist6_title']).to eq(player_2.player_original_info.pist6_title)
        expect(json['data']['player_list'][0]['winner_rate']).to eq(player_2.player_result.winner_rate)
        expect(json['data']['player_list'][0]['first_count']).to eq(player_2.player_result.first_count)
        expect(json['data']['player_list'][0]['first_place_count']).to eq(player_2.player_result.first_place_count)
        expect(json['data']['player_list'][0]['second_place_count']).to eq(player_2.player_result.second_place_count)
        expect(json['data']['player_list'][0]['round_result_list'][0]['promoter_year']).to eq(hold_daily.hold.promoter_year)
        expect(json['data']['player_list'][0]['round_result_list'][0]['season']).to eq(hold_daily.hold.period)
        expect(json['data']['player_list'][0]['round_result_list'][0]['round_code']).to eq(hold_daily.hold.round)
        expect(json['data']['player_list'][0]['round_result_list'][0]['event_date']).to eq(hold_daily.event_date.strftime('%F'))
        expect(json['data']['player_list'][0]['round_result_list'][0]['tt_record']).to eq(time_trial_player2.total_time.to_f.to_s)
        expect(json['data']['player_list'][0]['round_result_list'][0]['tt_rank']).to eq(time_trial_player2.ranking)
        expect(json['data']['player_list'][0]['round_result_list'][0]['last_event_code']).to eq(race2.event_code)
        expect(json['data']['player_list'][0]['round_result_list'][0]['last_details_code']).to eq(race2.details_code)
        expect(json['data']['player_list'][0]['round_result_list'][0]['last_race_rank']).to eq(race_result_player2_race2.rank)
        expect(json['data']['player_list'][0]['round_result_list'][1]).to eq(nil)

        expect(json['data']['player_list'][1]['id']).to eq(player.pf_250_regist_id)
        expect(json['data']['player_list'][1]['last_name_jp']).to eq(player.last_name_jp)
        expect(json['data']['player_list'][1]['last_name_en']).to eq(player.last_name_en)
        expect(json['data']['player_list'][1]['height']).to eq(player.player_original_info.free4&.to_f)
        expect(json['data']['player_list'][1]['weight']).to eq(player.player_original_info.free5&.to_f)
        expect(json['data']['player_list'][1]['country_code']).to eq(player.player_original_info.free2)
        expect(json['data']['player_list'][1]['catchphrase']).to eq(player.nickname)
        expect(json['data']['player_list'][1]['speed']).to eq(player.player_original_info.speed)
        expect(json['data']['player_list'][1]['stamina']).to eq(player.player_original_info.stamina)
        expect(json['data']['player_list'][1]['power']).to eq(player.player_original_info.power)
        expect(json['data']['player_list'][1]['technique']).to eq(player.player_original_info.technique)
        expect(json['data']['player_list'][1]['mental']).to eq(player.player_original_info.mental)
        expect(json['data']['player_list'][1]['evaluation']).to eq('SS')
        expect(json['data']['player_list'][1]['round_best']).to eq(player.player_original_info.round_best)
        expect(json['data']['player_list'][1]['year_best']).to eq(player.player_original_info.year_best)
        expect(json['data']['player_list'][1]['major_title']).to eq(player.player_original_info.major_title)
        expect(json['data']['player_list'][1]['pist6_title']).to eq(player.player_original_info.pist6_title)
        expect(json['data']['player_list'][1]['winner_rate']).to eq(player.player_result.winner_rate)
        expect(json['data']['player_list'][1]['first_count']).to eq(player.player_result.first_count)
        expect(json['data']['player_list'][1]['first_place_count']).to eq(player.player_result.first_place_count)
        expect(json['data']['player_list'][1]['second_place_count']).to eq(player.player_result.second_place_count)
        expect(json['data']['player_list'][1]['round_result_list'][0]['promoter_year']).to eq(hold_daily_2.hold.promoter_year)
        expect(json['data']['player_list'][1]['round_result_list'][0]['season']).to eq(hold_daily_2.hold.period)
        expect(json['data']['player_list'][1]['round_result_list'][0]['round_code']).to eq(hold_daily_2.hold.round)
        expect(json['data']['player_list'][1]['round_result_list'][0]['event_date']).to eq(hold_daily_2.event_date.strftime('%F'))
        expect(json['data']['player_list'][1]['round_result_list'][0]['tt_record']).to eq(time_trial_player.total_time.to_f.to_s)
        expect(json['data']['player_list'][1]['round_result_list'][0]['tt_rank']).to eq(time_trial_player1_2.ranking)
        expect(json['data']['player_list'][1]['round_result_list'][0]['last_event_code']).to eq(race_2_3.event_code)
        expect(json['data']['player_list'][1]['round_result_list'][0]['last_details_code']).to eq(race_2_3.details_code)
        expect(json['data']['player_list'][1]['round_result_list'][0]['last_race_rank']).to eq(race_result_player_race_2_1.rank)

        expect(json['data']['player_list'][1]['round_result_list'][1]['promoter_year']).to eq(hold_daily.hold.promoter_year)
        expect(json['data']['player_list'][1]['round_result_list'][1]['season']).to eq(hold_daily.hold.period)
        expect(json['data']['player_list'][1]['round_result_list'][1]['round_code']).to eq(hold_daily.hold.round)
        expect(json['data']['player_list'][1]['round_result_list'][1]['event_date']).to eq(hold_daily.event_date.strftime('%F'))
        expect(json['data']['player_list'][1]['round_result_list'][1]['tt_record']).to eq(time_trial_player.total_time.to_f.to_s)
        expect(json['data']['player_list'][1]['round_result_list'][1]['tt_rank']).to eq(time_trial_player.ranking)
        expect(json['data']['player_list'][1]['round_result_list'][1]['last_event_code']).to eq(race3.event_code)
        expect(json['data']['player_list'][1]['round_result_list'][1]['last_details_code']).to eq(race3.details_code)
        expect(json['data']['player_list'][1]['round_result_list'][1]['last_race_rank']).to eq(race_result_player_race3.rank)
      end

      context 'race_listの検証' do
        let(:players) { [player.pf_250_regist_id] }

        it '想定通りのrace_listが返ること,event_code,details_code,race_rankがある' do
          get_player_detail
          json = JSON.parse(response.body)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][0]['event_code']).to eq(race_2_5.event_code)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][1]['event_code']).to eq(race_2_4.event_code)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][2]['event_code']).to eq(race_2_1.event_code)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][3]['event_code']).to eq(race_2_2.event_code)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][3]['details_code']).to eq(race_2_2.details_code)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][3]['race_rank']).to eq(race_2_2.race_detail.race_result.race_result_players.find_by(pf_player_id: player.pf_player_id).rank)
          expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'].length).to eq(4)

          expect(json['data']['player_list'][0]['round_result_list'][1]['race_list'].length).to eq(3)
        end

        context 'event_codeがW X Yの場合' do
          before do
            race_2_5.update(event_code: 'W')
            race_2_4.update(event_code: 'X')
            race_2_1.update(event_code: 'Y')
          end

          it 'round_result_listのrace_listのevent_codeはTを返すこと' do
            get_player_detail
            json = JSON.parse(response.body)
            expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][0]['event_code']).to eq('T')
            expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][1]['event_code']).to eq('T')
            expect(json['data']['player_list'][0]['round_result_list'][0]['race_list'][2]['event_code']).to eq('T')
          end
        end
      end

      context 'round_result_listの検証' do
        let(:players) { [player.pf_250_regist_id, player_2.pf_250_regist_id] }

        before do
          race2.update(event_code: 'W')
          race_2_3.update(event_code: 'X')
          race3.update(event_code: 'Y')
        end

        it 'event_codeがW X Yの場合、 round_result_listのlast_event_codeはTを返すこと' do
          get_player_detail
          json = JSON.parse(response.body)
          expect(json['data']['player_list'][0]['round_result_list'][0]['last_event_code']).to eq('T')
          expect(json['data']['player_list'][1]['round_result_list'][0]['last_event_code']).to eq('T')
          expect(json['data']['player_list'][1]['round_result_list'][1]['last_event_code']).to eq('T')
        end
      end
    end

    context 'playersリストがあり且つlimitがない且つsort_keyがある場合' do
      let(:sort_key) { 'id' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { [player.pf_250_regist_id, player_2.pf_250_regist_id] }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it 'playersリストの内容でsort_keyでソートされてレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['total']).to eq(2)
        expect(json['data']['sort_key']).to eq(sort_key)
        expect(json['data']['limit']).to eq(limit)
        expect(json['data']['offset']).to eq(offset)
        expect(json['data']['player_list'].count).to eq(2)
        first_player_id = players.min_by(&:to_i)
        second_player_id = players.sort_by(&:to_i)[1]
        expect(json['data']['player_list'][0]['id']).to eq(first_player_id)
        expect(json['data']['player_list'][1]['id']).to eq(second_player_id)
        json['data']['player_list'].all? { |hash| expect(hash.keys).to match_array(player_detail_key) }
        expect(json['data']['player_list'][0]['id']).to be < json['data']['player_list'][1]['id']
      end
    end

    context 'filter_key(country)でフィルターされる場合' do
      let(:sort_key) { 'alphabet' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { 'country' }
      let(:filter_value) { '001' }
      let!(:player_3) { create(:player, pf_player_id: 997, name_en: 'TEST', country_code: '001') }
      let(:hold_player_3) { create(:hold_player, hold: hold, player: player_3) }

      before do
        create(:player_original_info, player_id: player_3.id, speed: 6, stamina: 1, power: 2, technique: 3, mental: 4,
                                      evaluation: 5, free2: '001', last_name_en: 'TEST', first_name_en: 'TEST', pf_250_regist_id: 1)
      end

      it 'country_codeがfilter_valueと一致されるplayerをレスポンスに渡す' do
        get_player_detail
        json = JSON.parse(response.body)
        pf_250_regist_ids = Player.includes(:player_original_info)
                                  .select { |player| player.player_original_info&.free2 == filter_value }
                                  .map(&:pf_250_regist_id)
        result_ids = json['data']['player_list'].map { |player| player['id'] }
        expect(result_ids).to match_array(pf_250_regist_ids)
      end
    end

    context 'filter_key(initial)でフィルターされる場合' do
      let(:sort_key) { 'alphabet' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { 'initial' }
      let(:filter_value) { player.player_original_info.last_name_en.chars.first }

      it 'name_enのイニシャルがfilter_valueと一致されるplayerをレスポンスに渡す' do
        get_player_detail
        json = JSON.parse(response.body)
        pf_250_regist_ids = Player.includes(:player_original_info)
                                  .select { |player| player.player_original_info&.last_name_en&.chars&.first == filter_value }
                                  .map(&:pf_250_regist_id)
        result_ids = json['data']['player_list'].map { |player| player['id'] }
        expect(result_ids).to match_array(pf_250_regist_ids)
      end
    end

    context 'filter_key(evaluation)でフィルターされる場合' do
      let(:sort_key) { 'alphabet' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { 'evaluation' }
      let(:filter_value) { 'C' }

      it 'evaluationがfilter_valueのrange範囲と一致されるplayerをレスポンスに渡す' do
        get_player_detail
        json = JSON.parse(response.body)
        players = Player.includes(:player_original_info)
                        .where.not(player_original_info: { pf_250_regist_id: nil })
                        .where.not(player_original_info: { last_name_en: nil })
                        .where.not(player_original_info: { first_name_en: nil })
        players = players.sorted_with_player_original_info('last_name_en').select { |player| (0..57).cover?(player.player_original_info&.evaluation) }
        ids = players.map(&:pf_250_regist_id).first(20)
        result_ids = json['data']['player_list'].map { |player| player['id'] }
        expect(result_ids).to match_array(ids)
      end
    end

    context 'filter_keyは指定したがfilter_valueは指定しない場合' do
      let(:sort_key) { 'alphabet' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { 'initial' }
      let(:filter_value) { nil }

      it 'name_enのイニシャルがfilter_valueと一致されるplayerをレスポンスに渡す' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'bad_request', 'detail' => 'filter_keyを指定する場合は、filter_valueを指定してください', 'status' => 400 })
      end
    end

    context 'playerのlast_name_enに値が入っていない場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { [player.pf_250_regist_id, player.pf_250_regist_id] }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { player.player_original_info.update_column(:last_name_en, nil) }

      it 'playerデータが取得できていない' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to match_array []
      end
    end

    context 'playerのfirst_name_enに値が入っていない場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { [player.pf_250_regist_id, player.pf_250_regist_id] }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { player.player_original_info.update_column(:first_name_en, nil) }

      it 'playerデータが取得できていない' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list']).to match_array []
      end
    end

    context 'playerの250登録番号に値が入っていない場合' do
      let(:sort_key) { 'alphabet' }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { 'evaluation' }
      let(:filter_value) { 'C' }

      before { player_2.player_original_info.update_column(:pf_250_regist_id, nil) }

      it 'evaluationでフィルターをかけて、250登録番号がnilのデータがないことを確認' do
        get_player_detail
        json = JSON.parse(response.body)
        players = Player.includes(:player_original_info)
                        .where.not(player_original_info: { pf_250_regist_id: nil })
                        .where.not(player_original_info: { last_name_en: nil })
                        .where.not(player_original_info: { first_name_en: nil })
        players = players.sorted_with_player_original_info('last_name_en').select { |player| (0..57).cover?(player.player_original_info&.evaluation) }
        ids = players.map(&:pf_250_regist_id).compact.first(20)
        result_ids = json['data']['player_list'].map { |player| player['id'] }
        expect(result_ids).to match_array(ids)
      end
    end

    context 'speedがnilの場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { PlayerOriginalInfo.update_all(speed: nil) }

      it 'playerのspeedがnilでレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['speed']).to eq nil
      end
    end

    context 'powerがnilの場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { PlayerOriginalInfo.update_all(power: nil) }

      it 'playerのpowerがnilでレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['power']).to eq nil
      end
    end

    context 'staminaがnilの場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { PlayerOriginalInfo.update_all(stamina: nil) }

      it 'playerのstaminaがnilでレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['stamina']).to eq nil
      end
    end

    context 'techniqueがnilの場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { PlayerOriginalInfo.update_all(technique: nil) }

      it 'playerのtechniqueがnilでレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['technique']).to eq nil
      end
    end

    context 'mentalがnilの場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { PlayerOriginalInfo.update_all(mental: nil) }

      it 'playerのmentalがnilでレスポンスパラメータが返ること' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['mental']).to eq nil
      end
    end

    context 'hold_statusが開催中の場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { [player_2.pf_250_regist_id] }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      before { hold.update(hold_status: :being_held) }

      it 'player_listの対象とならないこと' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['round_result_list'][0]).to eq(nil)
      end
    end

    context 'hold_statusが開催終了の場合' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { [player.pf_250_regist_id] }
      let(:filter_key) { nil }
      let(:filter_value) { nil }

      it '過去ラウンド結果リストの1番目に、開催終了した前回の開催の最終レースの結果を返すこと' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['round_result_list'][0]['promoter_year']).to eq(hold_daily_2.hold.promoter_year)
        expect(json['data']['player_list'][0]['round_result_list'][0]['season']).to eq(hold_daily_2.hold.period)
        expect(json['data']['player_list'][0]['round_result_list'][0]['round_code']).to eq(hold_daily_2.hold.round)
        expect(json['data']['player_list'][0]['round_result_list'][0]['event_date']).to eq(hold_daily_2.event_date.strftime('%F'))
        expect(json['data']['player_list'][0]['round_result_list'][0]['tt_record']).to eq(time_trial_player.total_time.to_f.to_s)
        expect(json['data']['player_list'][0]['round_result_list'][0]['tt_rank']).to eq(time_trial_player1_2.ranking)
        expect(json['data']['player_list'][0]['round_result_list'][0]['last_event_code']).to eq(race_2_3.event_code)
        expect(json['data']['player_list'][0]['round_result_list'][0]['last_details_code']).to eq(race_2_3.details_code)
        expect(json['data']['player_list'][0]['round_result_list'][0]['last_race_rank']).to eq(race_result_player_race_2_1.rank)
      end

      it '過去ラウンド結果リストの2番目に、開催終了した前々回の開催の最終レースの結果を返すこと' do
        get_player_detail
        json = JSON.parse(response.body)
        expect(json['data']['player_list'][0]['round_result_list'][1]['promoter_year']).to eq(hold_daily.hold.promoter_year)
        expect(json['data']['player_list'][0]['round_result_list'][1]['season']).to eq(hold_daily.hold.period)
        expect(json['data']['player_list'][0]['round_result_list'][1]['round_code']).to eq(hold_daily.hold.round)
        expect(json['data']['player_list'][0]['round_result_list'][1]['event_date']).to eq(hold_daily.event_date.strftime('%F'))
        expect(json['data']['player_list'][0]['round_result_list'][1]['tt_record']).to eq(time_trial_player.total_time.to_f.to_s)
        expect(json['data']['player_list'][0]['round_result_list'][1]['tt_rank']).to eq(time_trial_player.ranking)
        expect(json['data']['player_list'][0]['round_result_list'][1]['last_event_code']).to eq(race3.event_code)
        expect(json['data']['player_list'][0]['round_result_list'][1]['last_details_code']).to eq(race3.details_code)
        expect(json['data']['player_list'][0]['round_result_list'][1]['last_race_rank']).to eq(race_result_player_race3.rank)
      end
    end

    context '引退選手の検証' do
      let(:sort_key) { nil }
      let(:limit) { nil }
      let(:offset) { nil }
      let(:players) { nil }
      let(:filter_key) { nil }
      let(:filter_value) { nil }
      let(:target_player) do
        Player.includes(:player_original_info, :player_result)
              .where.not(player_original_info: { pf_250_regist_id: nil })
              .where.not(player_original_info: { last_name_en: nil })
              .where.not(player_original_info: { first_name_en: nil })
              .sorted_with_pf_250_regist_id.first
      end

      context 'target_playerが引退選手ではないとき' do
        it 'レスポンスに返ること' do
          get_player_detail
          json = JSON.parse(response.body)
          expect(json['data']['player_list'].map { |hash| hash['id'] })
            .to include(target_player.pf_250_regist_id)
        end
      end

      context 'target_playerが引退選手のとき' do
        before { create(:retired_player, player: target_player) }

        context 'playersリストに含まれないとき' do
          it 'レスポンスに返らないこと' do
            get_player_detail
            json = JSON.parse(response.body)
            expect(json['data']['player_list'].map { |hash| hash['id'] })
              .not_to include(target_player.pf_250_regist_id)
          end
        end

        context 'playersリストに含まれるとき' do
          let(:players) { [target_player.pf_250_regist_id] }

          it 'レスポンスに返ること' do
            get_player_detail
            json = JSON.parse(response.body)
            expect(json['data']['player_list'].map { |hash| hash['id'] })
              .to include(target_player.pf_250_regist_id)
          end
        end
      end
    end
  end

  describe 'GET /player_detail_revision' do
    subject(:get_player_detail_revision) { get v1_mt_datas_player_detail_revision_url, params: { player_id: player_id } }

    let(:player1) { create(:player, pf_player_id: 999, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join) }
    let(:player2) { create(:player, pf_player_id: 888, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join) }

    let!(:player_result1) { create(:player_result, player: player1, pf_player_id: player1.pf_player_id) }

    let!(:hold1) { create(:hold, hold_status: :finished_held) }
    let!(:hold2) { create(:hold, hold_status: :finished_held) }

    let!(:time_trial_result1) { create(:time_trial_result, hold: hold1) }

    let!(:hold_title1) { create(:hold_title, player_result: player_result1, pf_hold_id: hold1.pf_hold_id, round: 3) }

    let!(:hold_daily1) { create(:hold_daily, hold: hold1, hold_daily: 2) }
    let!(:hold_daily2) { create(:hold_daily, hold: hold2) }

    let!(:hold_daily_schedule1) { create(:hold_daily_schedule, hold_daily: hold_daily1) }

    let!(:race1) { create(:race, race_no: 1, event_code: 'aa', details_code: 'details1', hold_daily_schedule: hold_daily_schedule1, program_no: 1) }
    let!(:race2) { create(:race, race_no: 2, event_code: 'bb', details_code: 'details2', hold_daily_schedule: hold_daily_schedule1, program_no: 2) }

    let!(:race_detail1) { create(:race_detail, race: race1, hold_daily: 3, hold_day: '20210101', entries_id: '99999') }
    let!(:race_detail2) { create(:race_detail, race: race2, hold_daily: 2, hold_day: '20210120', entries_id: '88888') }

    let!(:race_result1) { create(:race_result, race_detail: race_detail1) }
    let!(:race_result2) { create(:race_result, race_detail: race_detail2) }

    let!(:player_race_result1) { create(:player_race_result, player: player1, hold_id: hold1.pf_hold_id, entries_id: race_detail1.entries_id) }

    let!(:time_trial_player1) { create(:time_trial_player, time_trial_result: time_trial_result1, pf_player_id: player1.pf_player_id) }

    let!(:race_result_player1) { create(:race_result_player, race_result: race_result1, pf_player_id: player1.pf_player_id, rank: 5) }
    let!(:race_result_player2) { create(:race_result_player, race_result: race_result2, pf_player_id: player1.pf_player_id, rank: 3) }

    before do
      create(:player_original_info, player: player1, pf_250_regist_id: '20', evaluation: 88, last_name_en: player1.name_en, first_name_en: player1.name_en)
      create(:player_original_info, player: player2, pf_250_regist_id: '25', last_name_en: player2.name_en, first_name_en: player2.name_en)

      create(:player_result, player: player2, pf_player_id: player2.pf_player_id)

      create(:time_trial_result, hold: hold2)

      create(:hold_daily_schedule, hold_daily: hold_daily2)

      create(:hold_title, player_result: player_result1, pf_hold_id: hold2.pf_hold_id, round: 4)

      create(:player_race_result, player: player1, hold_id: hold1.pf_hold_id, entries_id: race_detail2.entries_id)
      create(:player_race_result, player: player1, hold_id: hold2.pf_hold_id, entries_id: race_detail1.entries_id)
      create(:player_race_result, player: player1, hold_id: hold2.pf_hold_id, entries_id: race_detail2.entries_id)

      create(:time_trial_player, time_trial_result: time_trial_result1, pf_player_id: player2.pf_player_id)
    end

    context 'playerが存在しない場合' do
      let(:player_id) { nil }

      it 'nilが返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)
        expect(json['data']).to eq nil
      end
    end

    context 'playerがround_result、hold_list、race_result_listのデータを所有していない場合' do
      let(:player_id) { player2.player_original_info.pf_250_regist_id }

      it 'すべてのデータでnilまたは空配列が返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)
        expect(json['data']['player']['round_result']['promoter_year']).to eq nil
        expect(json['data']['player']['round_result']['season']).to eq nil
        expect(json['data']['player']['round_result']['round_code']).to eq nil
        expect(json['data']['player']['round_result']['event_date']).to eq nil
        expect(json['data']['player']['round_result']['tt_record']).to eq nil
        expect(json['data']['player']['round_result']['tt_rank']).to eq nil
        expect(json['data']['player']['round_result']['last_event_code']).to eq nil
        expect(json['data']['player']['round_result']['last_details_code']).to eq nil
        expect(json['data']['player']['round_result']['last_race_rank']).to eq nil
        expect(json['data']['player']['round_result']['race_list']).to eq []
        expect(json['data']['player']['hold_list']).to eq []
        expect(json['data']['player']['race_result_list']).to eq []
      end
    end

    context 'playerが存在する場合' do
      let(:player_id) { player1.player_original_info.pf_250_regist_id }

      it 'jsonは指定の属性を持つハッシュであること' do
        get_player_detail_revision
        json = JSON.parse(response.body)

        expect_player_key = %w[id last_name_jp first_name_jp last_name_en first_name_en birthday height weight country_code catchphrase speed stamina power technique mental evaluation round_best year_best major_title pist6_title winner_rate second_quinella_rate third_quinella_rate entry_count first_place_count second_place_count run_count first_count second_count third_count outside_count round_result hold_list race_result_list]
        expect_round_result_key = %w[promoter_year season round_code event_date tt_record tt_rank last_event_code last_details_code last_race_rank race_list]
        expect_hold_list_key = %w[promoter_year season round_code]
        expect_race_result_list_key = %w[hold_id promoter_year first_day season round_code race_list tt_record tt_rank]
        expect_race_list_key = %w[race_id time rank race_no event_code]

        expect(json['data']['player'].keys).to match_array(expect_player_key)
        expect(json['data']['player']['round_result'].keys).to match_array(expect_round_result_key)
        expect(json['data']['player']['hold_list'][0].keys).to match_array(expect_hold_list_key)
        expect(json['data']['player']['race_result_list'][0].keys).to match_array(expect_race_result_list_key)
        expect(json['data']['player']['race_result_list'][0]['race_list'][0].keys).to match_array(expect_race_list_key)
      end

      it 'playerの内容でレスポンスパラメータが返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)

        expect(json['data']['player']['id']).to eq player1.player_original_info.pf_250_regist_id
        expect(json['data']['player']['last_name_jp']).to eq player1.player_original_info.last_name_jp
        expect(json['data']['player']['first_name_jp']).to eq player1.player_original_info.first_name_jp
        expect(json['data']['player']['last_name_en']).to eq player1.player_original_info.last_name_en
        expect(json['data']['player']['first_name_en']).to eq player1.player_original_info.first_name_en
        expect(json['data']['player']['birthday']).to eq '1989-03-21'
        expect(json['data']['player']['height']).to eq player1.player_original_info.free4.to_f
        expect(json['data']['player']['weight']).to eq player1.player_original_info.free5.to_f
        expect(json['data']['player']['country_code']).to eq player1.player_original_info.free2
        expect(json['data']['player']['catchphrase']).to eq player1.player_original_info.nickname
        expect(json['data']['player']['speed']).to eq player1.speed
        expect(json['data']['player']['stamina']).to eq player1.stamina
        expect(json['data']['player']['power']).to eq player1.power
        expect(json['data']['player']['technique']).to eq player1.technique
        expect(json['data']['player']['mental']).to eq player1.mental
        expect(json['data']['player']['evaluation']).to eq 'S'
        expect(json['data']['player']['round_best']).to eq player1.player_original_info.round_best
        expect(json['data']['player']['year_best']).to eq player1.player_original_info.year_best
        expect(json['data']['player']['major_title']).to eq player1.player_original_info.major_title
        expect(json['data']['player']['pist6_title']).to eq player1.player_original_info.pist6_title
        expect(json['data']['player']['winner_rate']).to eq player1.player_result.winner_rate
        expect(json['data']['player']['second_quinella_rate']).to eq player1.player_result.second_quinella_rate
        expect(json['data']['player']['third_quinella_rate']).to eq player1.player_result.third_quinella_rate
        expect(json['data']['player']['entry_count']).to eq player1.player_result.entry_count
        expect(json['data']['player']['first_place_count']).to eq player1.player_result.first_place_count
        expect(json['data']['player']['second_place_count']).to eq player1.player_result.second_place_count
        expect(json['data']['player']['run_count']).to eq player1.player_result.run_count
        expect(json['data']['player']['first_count']).to eq player1.player_result.first_count
        expect(json['data']['player']['second_count']).to eq player1.player_result.second_count
        expect(json['data']['player']['third_count']).to eq player1.player_result.third_count
        expect(json['data']['player']['outside_count']).to eq player1.player_result.outside_count

        expect(json['data']['player']['round_result']['promoter_year']).to eq hold1.promoter_year
        expect(json['data']['player']['round_result']['season']).to eq hold1.period
        expect(json['data']['player']['round_result']['round_code']).to eq hold1.round
        expect(json['data']['player']['round_result']['event_date']).to eq hold_daily2.event_date.to_s
        expect(json['data']['player']['round_result']['tt_record']).to eq time_trial_player1.total_time.to_f.to_s
        expect(json['data']['player']['round_result']['tt_rank']).to eq time_trial_player1.ranking
        expect(json['data']['player']['round_result']['last_event_code']).to eq race2.event_code
        expect(json['data']['player']['round_result']['last_details_code']).to eq race2.details_code
        expect(json['data']['player']['round_result']['last_race_rank']).to eq race_result_player2.rank
        expect(json['data']['player']['round_result']['race_list'][0]['event_code']).to eq race1.event_code
        expect(json['data']['player']['round_result']['race_list'][0]['details_code']).to eq race1.details_code
        expect(json['data']['player']['round_result']['race_list'][0]['race_rank']).to eq race_result_player1.rank

        expect(json['data']['player']['hold_list'][0]['promoter_year']).to eq hold1.promoter_year
        expect(json['data']['player']['hold_list'][0]['season']).to eq hold1.period
        expect(json['data']['player']['hold_list'][0]['round_code']).to eq hold_title1.round
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['hold_id']).to eq player_race_result1.hold_id
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['promoter_year']).to eq hold1.promoter_year
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['first_day']).to eq hold1.first_day.to_s
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['season']).to eq hold1.period
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['tt_record']).to eq time_trial_player1.total_time.to_f.to_s
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['tt_rank']).to eq time_trial_player1.ranking
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['round_code']).to eq hold1.round
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['race_list'].find { |j| j['race_id'] == race1.id }['race_id']).to eq race1.id
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['race_list'].find { |j| j['race_id'] == race1.id }['time']).to eq player_race_result1.time
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['race_list'].find { |j| j['race_id'] == race1.id }['rank']).to eq player_race_result1.rank.to_s
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['race_list'].find { |j| j['race_id'] == race1.id }['race_no']).to eq player_race_result1.race_no
        expect(json['data']['player']['race_result_list'].find { |j| j['hold_id'] == hold1.pf_hold_id }['race_list'].find { |j| j['race_id'] == race1.id }['event_code']).to eq race1.event_code
      end

      it 'playerのround_resultのrace_listが全て(2件)返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)
        expect(json['data']['player']['round_result']['race_list'].count).to eq 2
      end

      it 'playerのhold_listが全て(2件)返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)
        expect(json['data']['player']['hold_list'].count).to eq 2
      end

      it 'playerのrace_result_listが全て(2件)返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)
        expect(json['data']['player']['race_result_list'].count).to eq 2
      end

      it 'playerのrace_listが全て(2件)返ること' do
        get_player_detail_revision
        json = JSON.parse(response.body)
        expect(json['data']['player']['race_result_list'][0]['race_list'].count).to eq 2
      end

      context 'playerのround_resultのevent_codeがWの場合' do
        before { Race.update_all(event_code: 'W') }

        it 'last_event_codeはTを返すこと' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_result']['last_event_code']).to eq 'T'
        end
      end

      context 'playerのround_resultのrace_listのevent_codeがXの場合' do
        before { Race.update_all(event_code: 'X') }

        it 'last_event_codeはTを返すこと' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_result']['race_list'][0]['event_code']).to eq 'T'
        end
      end

      context 'playerのrace_result_listのrace_listのevent_codeがYの場合' do
        before { Race.update_all(event_code: 'Y') }

        it 'event_codeはTを返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['race_list'][0]['event_code']).to eq 'T'
        end
      end

      context 'last_name_jpがnilの場合' do
        before { PlayerOriginalInfo.update_all(last_name_jp: nil) }

        it 'playerのlast_name_jpがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['last_name_jp']).to eq nil
        end
      end

      context 'first_name_jpがnilの場合' do
        before { PlayerOriginalInfo.update_all(first_name_jp: nil) }

        it 'first_name_jpがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['first_name_jp']).to eq nil
        end
      end

      context 'birthdayがnilの場合' do
        before { PlayerOriginalInfo.update_all(free3: nil) }

        it 'playerのbirthdayがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['birthday']).to eq nil
        end
      end

      context 'heightがnilの場合' do
        before { PlayerOriginalInfo.update_all(free4: nil) }

        it 'playerのheightがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['height']).to eq nil
        end
      end

      context 'weightがnilの場合' do
        before { PlayerOriginalInfo.update_all(free5: nil) }

        it 'playerのweightがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['weight']).to eq nil
        end
      end

      context 'country_codeがnilの場合' do
        before { PlayerOriginalInfo.update_all(free2: nil) }

        it 'playerのcountry_codeがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['country_code']).to eq nil
        end
      end

      context 'nicknameがnilの場合' do
        before { PlayerOriginalInfo.update_all(nickname: nil) }

        it 'playerのcatchphraseがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['catchphrase']).to eq nil
        end
      end

      context 'speedがnilの場合' do
        before { PlayerOriginalInfo.update_all(speed: nil) }

        it 'playerのspeedがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['speed']).to eq nil
        end
      end

      context 'staminaがnilの場合' do
        before { PlayerOriginalInfo.update_all(stamina: nil) }

        it 'playerのstaminaがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['stamina']).to eq nil
        end
      end

      context 'powerがnilの場合' do
        before { PlayerOriginalInfo.update_all(power: nil) }

        it 'playerのpowerがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['power']).to eq nil
        end
      end

      context 'techniqueがnilの場合' do
        before { PlayerOriginalInfo.update_all(technique: nil) }

        it 'playerのtechniqueがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['technique']).to eq nil
        end
      end

      context 'mentalがnilの場合' do
        before { PlayerOriginalInfo.update_all(mental: nil) }

        it 'playerのmentalがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['mental']).to eq nil
        end
      end

      context 'evaluationがnilの場合' do
        before { PlayerOriginalInfo.update_all(evaluation: nil) }

        it 'playerのevaluationがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['evaluation']).to eq nil
        end
      end

      context 'round_bestがnilの場合' do
        before { PlayerOriginalInfo.update_all(round_best: nil) }

        it 'playerのround_bestがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_best']).to eq nil
        end
      end

      context 'year_bestがnilの場合' do
        before { PlayerOriginalInfo.update_all(year_best: nil) }

        it 'playerのyear_bestがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['year_best']).to eq nil
        end
      end

      context 'major_titleがnilの場合' do
        before { PlayerOriginalInfo.update_all(major_title: nil) }

        it 'playerのmajor_titleがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['major_title']).to eq nil
        end
      end

      context 'pist6_titleがnilの場合' do
        before { PlayerOriginalInfo.update_all(pist6_title: nil) }

        it 'playerのpist6_titleがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['pist6_title']).to eq nil
        end
      end

      context 'winner_rateがnilの場合' do
        before { PlayerResult.update_all(winner_rate: nil) }

        it 'playerのwinner_rateがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['winner_rate']).to eq nil
        end
      end

      context 'second_quinella_rateがnilの場合' do
        before { PlayerResult.update_all(second_quinella_rate: nil) }

        it 'playerのsecond_quinella_rateがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['second_quinella_rate']).to eq nil
        end
      end

      context 'third_quinella_rateがnilの場合' do
        before { PlayerResult.update_all(third_quinella_rate: nil) }

        it 'playerのthird_quinella_rateがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['third_quinella_rate']).to eq nil
        end
      end

      context 'entry_countがnilの場合' do
        before { PlayerResult.update_all(entry_count: nil) }

        it 'playerのentry_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['entry_count']).to eq nil
        end
      end

      context 'first_place_countがnilの場合' do
        before { PlayerResult.update_all(first_place_count: nil) }

        it 'playerのfirst_place_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['first_place_count']).to eq nil
        end
      end

      context 'second_place_countがnilの場合' do
        before { PlayerResult.update_all(second_place_count: nil) }

        it 'playerのsecond_place_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['second_place_count']).to eq nil
        end
      end

      context 'run_countがnilの場合' do
        before { PlayerResult.update_all(run_count: nil) }

        it 'playerのrun_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['run_count']).to eq nil
        end
      end

      context 'first_countがnilの場合' do
        before { PlayerResult.update_all(first_count: nil) }

        it 'playerのfirst_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['first_count']).to eq nil
        end
      end

      context 'second_countがnilの場合' do
        before { PlayerResult.update_all(second_count: nil) }

        it 'playerのsecond_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['second_count']).to eq nil
        end
      end

      context 'third_countがnilの場合' do
        before { PlayerResult.update_all(third_count: nil) }

        it 'playerのthird_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['third_count']).to eq nil
        end
      end

      context 'outside_countがnilの場合' do
        before { PlayerResult.update_all(outside_count: nil) }

        it 'playerのoutside_countがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['outside_count']).to eq nil
        end
      end

      context 'total_timeがnilの場合' do
        before { TimeTrialPlayer.update_all(total_time: nil) }

        it 'playerのround_resultのtt_recordがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_result']['tt_record']).to eq nil
        end
      end

      context 'rankingがnilの場合' do
        before { TimeTrialPlayer.update_all(ranking: nil) }

        it 'playerのround_resultのtt_recordがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_result']['tt_rank']).to eq nil
        end
      end

      context 'details_codeがnilの場合' do
        before { Race.update_all(details_code: nil) }

        it 'playerのround_resultのlast_details_codeがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_result']['last_details_code']).to eq nil
        end
      end

      context 'race_result_playerのrankがnilの場合' do
        before { RaceResultPlayer.update_all(rank: nil) }

        it 'playerのround_resultのlast_race_rankがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['round_result']['last_race_rank']).to eq nil
        end
      end

      context 'hold_listのpromoter_yearがnilの場合' do
        before { Hold.update_all(promoter_year: nil) }

        it 'playerのhold_listのevent_dateがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['hold_list'][0]['promoter_year']).to eq nil
        end
      end

      context 'hold_listのseasonがnilの場合' do
        before { Hold.update_all(period: nil) }

        it 'playerのhold_listのseasonがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['hold_list'][0]['season']).to eq nil
        end
      end

      context 'hold_listのround_codeがnilの場合' do
        before { HoldTitle.update_all(round: nil) }

        it 'playerのhold_listのround_codeがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['hold_list'][0]['round_code']).to eq nil
        end
      end

      context 'hold_idがnilの場合' do
        before { PlayerRaceResult.update_all(hold_id: nil) }

        it 'playerのrace_result_listのhold_idがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['hold_id']).to eq nil
        end
      end

      context 'race_result_listのpromoter_yearがnilの場合' do
        before { Hold.update_all(promoter_year: nil) }

        it 'playerのrace_result_listのpromoter_yearがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['promoter_year']).to eq nil
        end
      end

      context 'race_result_listのseasonがnilの場合' do
        before { Hold.update_all(period: nil) }

        it 'playerのrace_result_listのseasonがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['season']).to eq nil
        end
      end

      context 'race_result_listのround_codeがnilの場合' do
        before { Hold.update_all(round: nil) }

        it 'playerのrace_result_listのround_codeがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['round_code']).to eq nil
        end
      end

      context 'timeがnilの場合' do
        before { PlayerRaceResult.update_all(time: nil) }

        it 'playerのrace_result_listのrace_listのtimeがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['race_list'][0]['time']).to eq nil
        end
      end

      context 'event_codeがnilの場合' do
        before { Race.update_all(event_code: nil) }

        it 'playerのrace_result_listのrace_listのevent_codeがnilでレスポンスパラメータが返ること' do
          get_player_detail_revision
          json = JSON.parse(response.body)
          expect(json['data']['player']['race_result_list'][0]['race_list'][0]['event_code']).to eq nil
        end
      end

      context 'rankが有効ではない場合' do
        let!(:result_event_code1) { create(:result_event_code, race_result_player: race_result_player1, priority: 1) }
        let!(:word_code1) { create(:word_code, identifier: 'V12', code: result_event_code1.event_code, name1: '欠') }

        before do
          create(:word_code, identifier: 'V15', code: result_event_code1.event_code, name1: '失')
          create(:word_code, identifier: 'V12', name1: '他')
          create(:result_event_code, race_result_player: race_result_player1, priority: 2)
        end

        context 'rankが0の場合' do
          before { PlayerRaceResult.update_all(rank: 0) }

          it 'playerのrace_result_listのrace_listのrankが開催マスタからの値でレスポンスパラメータが返ること' do
            get_player_detail_revision
            json = JSON.parse(response.body)
            expect(json['data']['player']['race_result_list'][0]['race_list'][0]['rank']).to eq word_code1.name1
          end
        end

        context 'rankがnilの場合' do
          before { PlayerRaceResult.update_all(rank: nil) }

          it 'playerのrace_result_listのrace_listのrankが開催マスタからの値でレスポンスパラメータが返ること' do
            get_player_detail_revision
            json = JSON.parse(response.body)
            expect(json['data']['player']['race_result_list'][0]['race_list'][0]['rank']).to eq word_code1.name1
          end
        end
      end
    end
  end

  describe 'GET /past_races' do
    subject(:get_past_races) { get v1_mt_datas_past_races_url, params: params }

    let!(:hold) { create(:hold, promoter_year: 2021, period: 1, round: 1) }
    let!(:hold2) { create(:hold, promoter_year: 2021, period: 2, round: 1) }
    let!(:hold_daily) { create(:hold_daily, :with_final_race, hold: hold) }
    let!(:hold_daily2) { create(:hold_daily, :with_race_result, hold: hold2) }
    let!(:hold_daily_schedule) { hold_daily.hold_daily_schedules.first }
    let!(:hold_daily_schedule2) { hold_daily2.hold_daily_schedules.first }

    context '存在するholdデータのパラメータでリクエストされた場合' do
      let(:params) { { promoter_year: 2021, season: 'spring', round_code: 1 } }

      it 'レスポンスパラメータの確認' do
        get_past_races
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(hold.promoter_year)
        expect(json['data']['season']).to eq(hold.period)
        expect(json['data']['race_list'][0]['id']).to eq(hold_daily_schedule.races.first.id)
        expect(json['data']['race_list'][0]['event_date']).to eq(hold_daily.event_date.strftime('%Y-%m-%d'))
        expect(json['data']['race_list'][0]['day_night']).to eq(hold_daily_schedule.daily_no_before_type_cast)
        expect(json['data']['race_list'][0]['post_time']).to eq(time_format(hold_daily_schedule.races.first.post_time))
        expect(json['data']['race_list'][0]['name']).to eq(hold_daily_schedule.races.first.event_code)
        expect(json['data']['race_list'][0]['detail']).to eq(hold_daily_schedule.races.first.details_code)
        expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        expect(json['data']['race_list'][0]['race_status']).to eq(2)
        expect(json['data']['race_list'][0]['player_list'].size).to eq(hold_daily_schedule.races.first.race_detail.race_players.size)
      end

      context '出走表がなく、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは2になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.destroy
          hold.update(hold_status: [*2..9].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(2)
        end
      end

      context '出走表がなく、開催が終了していない場合（hold_statusが0、1の場合）、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.destroy
          hold.update(hold_status: [0, 1].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        end
      end

      context 'race_statusが0またはnilで、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.update(race_status: ['0', nil].sample)
          hold.update(hold_status: [*2..9].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        end
      end

      context 'race_statusが0またはnilで、開催が終了していない場合（hold_statusが0、1の場合））、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.update(race_status: ['0', nil].sample)
          hold.update(hold_status: [0, 1].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        end
      end

      context 'race_statusが0,10,15,nil以外の場合、cancel_statusは2になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.update(race_status: '20')
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(2)
        end
      end

      context 'race_statusが0,10,15,nilの場合、cancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.update(race_status: ['0', '10', '15', nil].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        end
      end

      context '出走表がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.destroy
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走選手がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.race_players.destroy_all
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走表、出走選手はあるが、レース結果がない場合、対象のrace_listのrace_statusは2になること' do
        it 'レスポンスパラメータの確認' do
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['race_status']).to eq(2)
        end
      end
    end

    context 'params指定しない場合' do
      let(:params) { nil }

      it '最後にレース成立後に終了したレースが属するシーズンとシリーズをベースに取得する' do
        get_past_races
        json = JSON.parse(response.body)
        expect(json['data']['promoter_year']).to eq(hold2.promoter_year)
        expect(json['data']['season']).to eq(hold2.period)
        expect(json['data']['race_list'][0]['id']).to eq(hold_daily_schedule2.races.first.id)
        expect(json['data']['race_list'][0]['name']).to eq(hold_daily_schedule2.races.first.event_code)
        expect(json['data']['race_list'][0]['detail']).to eq(hold_daily_schedule2.races.first.details_code)
        expect(json['data']['race_list'][0]['event_date']).to eq(hold_daily2.event_date.strftime('%Y-%m-%d'))
        expect(json['data']['race_list'][0]['day_night']).to eq(hold_daily_schedule2.daily_no_before_type_cast)
        expect(json['data']['race_list'][0]['post_time']).to eq(time_format(hold_daily_schedule2.races.first.post_time))
        expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        expect(json['data']['race_list'][0]['race_status']).to eq(3)
        expect(json['data']['race_list'][0]['player_list'].size).to eq(hold_daily_schedule2.races.first.race_detail.race_players.size)
      end
    end

    context '開催が見つからない場合' do
      let(:params) { { promoter_year: 1900, season: 'spring' } }

      it 'nilを返す' do
        get_past_races
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'paramsが足りない場合' do
      let(:params) { { promoter_year: 1900 } }

      it 'エラーメッセージの確認' do
        get_past_races
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('パラメータを指定する場合は、promoter_yearとseasonを指定してください')
      end
    end

    context '出走表あるいは出走表に選手が入っていない場合' do
      let!(:hold3) { create(:hold, promoter_year: 2021, period: 1, round: 3) }
      let(:hold_daily_3) { create(:hold_daily, hold: hold3) }
      let(:hold_daily_schedule_3) { create(:hold_daily_schedule, hold_daily: hold_daily_3) }
      let(:params) { { promoter_year: 2021, season: 'spring', round_code: 3 } }
      let!(:race) { create(:race, hold_daily_schedule: hold_daily_schedule_3) }

      before do
        create(:race_detail, race: race)
      end

      context '出走表がなく、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは2になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule_3.races.first.race_detail.destroy
          hold3.update(hold_status: [*2..9].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(2)
        end
      end

      context '出走表がなく、開催が終了していない場合（hold_statusが0、1の場合）、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          hold_daily_schedule_3.races.first.race_detail.destroy
          hold3.update(hold_status: [0, 1].sample)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['cancel_status']).to eq(1)
        end
      end

      context '出走表がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule_3.races.first.race_detail.destroy
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走選手がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule_3.races.first.race_detail.race_players.destroy_all
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走表、出走選手はあるが、レース結果がない場合、対象のrace_listのrace_statusは2になること' do
        it 'レスポンスパラメータの確認' do
          create(:race_player, race_detail: hold_daily_schedule_3.races.first.race_detail)
          get_past_races
          json = JSON.parse(response.body)
          expect(json['data']['race_list'][0]['race_status']).to eq(2)
        end
      end
    end

    context 'params指定しない場合、最後にレース成立後に終了したレースの開催のpromoter_yearもしくはperiodがない場合' do
      let(:hold3) { create(:hold, promoter_year: 2021, round: 1, period: nil) }
      let(:hold4) { create(:hold, promoter_year: nil, period: 2, round: 1) }
      let(:params) { nil }

      it 'periodがない場合、dataはnilを渡す' do
        create(:hold_daily, :with_race_result, hold: hold3)
        get_past_races
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end

      it 'promoter_yearがない場合、dataはnilを渡す' do
        create(:hold_daily, :with_race_result, hold: hold4)
        get_past_races
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'event_codeがXの場合' do
      let(:params) { { promoter_year: 2021, season: 'spring', round_code: 1 } }

      it 'raceのevent_codeがXの場合、nameでTを返すこと' do
        hold_daily.hold_daily_schedules.first.races.each { |r| r.update(event_code: 'X') }
        get_past_races
        json = JSON.parse(response.body)
        expect(json['data']['race_list'][0]['name']).to eq('T')
      end
    end
  end

  describe 'GET /race_details' do
    subject(:player_detail_key) { %w[id last_name_jp first_name_jp last_name_en first_name_en birthday height weight country_code catchphrase speed stamina power technique mental evaluation round_best year_best major_title pist6_title winner_rate first_place_count second_place_count first_count round_result_list] }

    let(:get_race_detail) { get v1_mt_datas_race_details_url, params: { race_id: race_id } }
    let!(:race) { create(:race, :with_race_detail) }

    context 'リクエストパラメータのrace_idがない場合' do
      let(:race_id) { nil }

      it 'エラーになることを確認' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('race_idを入力してください')
      end
    end

    context '対象ののrace_idがない場合' do
      let(:race_id) { '9999' }

      it 'エラーにならないことを確認' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context '対象のrace_idがある場合' do
      let(:race_id) { race.id }

      it 'レスポンスパラメータが正しいこと' do
        race_result_player = RaceResultPlayer.first
        race_result_player.update(bike_no: 5, last_lap: 1.012e1)
        race.hold_daily_schedule.hold_daily.hold.update(hold_status: :finished_held)
        race.update(post_time: '1400')
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']['name']).to eq(race.event_code)
        expect(json['data']['detail']).to eq(race.details_code)
        expect(json['data']['cancel_status']).to eq(1)
        expect(json['data']['hold_daily_schedule']['id']).to eq(race.hold_daily_schedule.id)
        expect(json['data']['hold_daily_schedule']['promoter_year']).to eq(race.hold_daily_schedule.hold_daily.hold.promoter_year)
        expect(json['data']['hold_daily_schedule']['season']).to eq(race.hold_daily_schedule.hold_daily.hold.period)
        expect(json['data']['hold_daily_schedule']['round_code']).to eq(race.hold_daily_schedule.hold_daily.hold.round)
        expect(json['data']['hold_daily_schedule']['event_date']).to eq(race.hold_daily_schedule.hold_daily.event_date.strftime('%F'))
        expect(json['data']['hold_daily_schedule']['day_night']).to eq(race.hold_daily_schedule.daily_no_before_type_cast)
        expect(json['data']['race_table'][0]['bike_no']).to eq(race.race_detail.race_players.first.bike_no)
        expect(json['data']['race_table'][0]['cancel']).to eq(race.race_detail.race_players.first.miss)
        expect(json['data']['race_table'][0]['tt_time']).to eq(race.hold_daily_schedule.hold_daily.hold.time_trial_result.time_trial_players.first.total_time.to_f)
        expect(json['data']['race_table'][0]['tt_rank']).to eq(race.hold_daily_schedule.hold_daily.hold.time_trial_result.time_trial_players.first.ranking)
        expect(json['data']['race_table'][0]['odds']).to eq(1.1)
        expect(json['data']['race_table'][0]['race_time']).to eq(race_result_player.last_lap.to_f)
        expect(json['data']['race_table'][0]['race_rank']).to eq(race.race_detail.race_result.race_result_players.first.rank)
        expect(json['data']['race_table'][0]['race_difference_code']).to eq(race.race_detail.race_result.race_result_players.first.difference_code)
        expect(json['data']['race_table'][0]['gear']).to eq(race.race_detail.race_players.first.gear&.to_f)
        expect(json['data']['race_table'][0]['player'].keys).to match_array(player_detail_key)
        expect(json['data']['race_table'][0]['player']['id']).not_to eq(nil)

        race_player_pf_player_id = race.race_detail.race_players.first.pf_player_id
        race_player_pf_250_regist_id = Player.find_by(pf_player_id: race_player_pf_player_id).pf_250_regist_id
        expect(json['data']['race_table'][0]['player']['id']).to eq(race_player_pf_250_regist_id)
        expect(json['data']['race_table'][0]['player']['round_result_list'][0]['event_date']).to eq(race.hold_daily_schedule.hold_daily.event_date.strftime('%F'))
        expect(json['data']['race_table'][0]['player']['round_result_list'][0]['tt_record']).to eq(race.hold_daily_schedule.hold_daily.hold.time_trial_result.time_trial_players.first.total_time.to_f.to_s)
        expect(json['data']['race_table'][0]['player']['round_result_list'][0]['tt_rank']).to eq(race.hold_daily_schedule.hold_daily.hold.time_trial_result.time_trial_players.first.ranking)
        expect(json['data']['race_table'][0]['player']['round_result_list'][0]['last_event_code']).to eq(race.event_code)
        expect(json['data']['race_table'][0]['player']['round_result_list'][0]['last_details_code']).to eq(race.details_code)
        expect(json['data']['race_table'][0]['player']['round_result_list'][0]['last_race_rank']).to eq(race.race_detail.race_result.race_result_players.first.rank)

        expect(json['data']['race_table'][0]['winner_rate']).to eq nil
        expect(json['data']['race_table'][0]['2quinella_rate']).to eq nil
        expect(json['data']['race_table'][0]['3quinella_rate']).to eq nil

        expect(json['data']['race_table'][0]['last_round_result']).to eq nil

        expect(json['data']['free_text']).to eq(race.formated_free_text)
        expect(json['data']['race_movie_yt_id']).to eq(race.race_movie_yt_id)
        expect(json['data']['interview_movie_yt_id']).to eq(race.interview_movie_yt_id)
        expect(json['data']['payoff_list'][0]['payoff_type']).to eq(race.race_detail.payoff_lists.first.payoff_type_before_type_cast)
        expect(json['data']['payoff_list'][0]['vote_type']).to eq(race.race_detail.payoff_lists.first.vote_type_before_type_cast)
        expect(json['data']['payoff_list'][0]['tip1']).to eq(race.race_detail.payoff_lists.first.tip1)
        expect(json['data']['payoff_list'][0]['tip2']).to eq(race.race_detail.payoff_lists.first.tip2)
        expect(json['data']['payoff_list'][0]['tip3']).to eq(race.race_detail.payoff_lists.first.tip3)
        expect(json['data']['payoff_list'][0]['payoff']).to eq(race.race_detail.payoff_lists.first.payoff)

        expect(json['data']['post_time']).to eq(time_format(race.post_time))
      end

      context 'race_statusが0,10,15,nil以外の場合、cancel_statusは2になること' do
        it ' レスポンスパラメータの確認' do
          race.race_detail.update(race_status: '20')
          get_race_detail
          json = JSON.parse(response.body)
          expect(json['data']['cancel_status']).to eq(2)
        end
      end

      context 'race_statusが0,10,15,nilの場合、cancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          race.race_detail.update(race_status: ['0', '10', '15', nil].sample)
          get_race_detail
          json = JSON.parse(response.body)
          expect(json['data']['cancel_status']).to eq(1)
        end
      end

      context 'race_statusが0またはnilで、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          race.race_detail.update(race_status: ['0', nil].sample)
          race.hold_daily_schedule.hold_daily.hold.update(hold_status: [*2..9].sample)
          get_race_detail
          json = JSON.parse(response.body)
          expect(json['data']['cancel_status']).to eq(1)
        end
      end

      context 'race_statusが0またはnilで、開催が終了していない場合（hold_statusが0、1の場合））、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          race.race_detail.update(race_status: ['0', nil].sample)
          race.hold_daily_schedule.hold_daily.hold.update(hold_status: [0, 1].sample)
          get_race_detail
          json = JSON.parse(response.body)
          expect(json['data']['cancel_status']).to eq(1)
        end
      end

      context '勝率がある場合' do
        let!(:race_player_stat) { create(:race_player_stat, :with_data, race_player: race.race_detail.race_players.first) }

        it 'レスポンスに勝率が設定されていること' do
          get_race_detail
          json = JSON.parse(response.body)
          expect(json['data']['race_table'][0]['winner_rate']).to eq(race_player_stat.winner_rate)
          expect(json['data']['race_table'][0]['2quinella_rate']).to eq(race_player_stat.second_quinella_rate)
          expect(json['data']['race_table'][0]['3quinella_rate']).to eq(race_player_stat.third_quinella_rate)
        end
      end

      context '前回成績がある場合' do
        let(:promoter_year) { rand(2000..2100) }
        let(:period) { %w[period1 period2 quarter1 quarter2 quarter3 quarter4].sample }
        let(:round) { rand(100..999) }
        let(:first_day) { rand(Date.new(2020, 1, 1)..Date.new(2100, 12, 31)) }
        let(:total_time) { rand(0..3000) / 100.0 }
        let(:tt_rank) { rand(1..99) }
        let(:event_code) { %w[U V R 2 T 3].sample(5) }
        let(:details_code) { %w[D1 E2 U3 T4].sample(5) }
        let(:race_rank) { Array.new(4) { rand(1..99) } }

        before do
          pf_player_id = race.race_detail.race_players.first.pf_player_id
          player = Player.find_by(pf_player_id: pf_player_id)
          hold = race.hold_daily_schedule.hold_daily.hold

          last_hold_player = create(:hold_player, player: player)
          last_hold = last_hold_player.hold
          last_hold.update(promoter_year: promoter_year)
          last_hold.update(period: period)
          last_hold.update(round: round)
          last_hold.update(first_day: first_day)
          tt_result = create(:time_trial_result, hold: last_hold)
          create(:time_trial_player, time_trial_result: tt_result, pf_player_id: pf_player_id, total_time: total_time, ranking: tt_rank)

          last_hold_dailys = [create(:hold_daily, hold: last_hold)]
          last_hold_dailys += [create(:hold_daily, hold: last_hold, event_date: (last_hold_dailys[0].event_date + 1.day))]
          [[4, 2], [1, 3, 12]].each.with_index do |no_list, idx|
            # program_no を指定することで出力がソートされていることを確認する
            last_hold_daily_schedule = create(:hold_daily_schedule, hold_daily: last_hold_dailys[idx])
            no_list.each.with_index do |no, idx2|
              array_idx = (idx * 2) + idx2
              last_race = create(:race, hold_daily_schedule: last_hold_daily_schedule, program_no: no)
              last_race_detail = create(:race_detail, race: last_race, event_code: event_code[array_idx], details_code: details_code[array_idx])
              last_race_result = create(:race_result, race_detail: last_race_detail)
              rank = no == 12 ? [nil, 0].sample : race_rank[array_idx]
              last_race_result_player = create(:race_result_player, race_result: last_race_result, rank: rank)
              create(:hold_player_result, hold_player: last_hold_player, race_result_player: last_race_result_player)
              if no == 12
                create(:result_event_code, race_result_player: last_race_result_player, event_code: '310001', priority: 0)
                create(:result_event_code, race_result_player: last_race_result_player, event_code: '120000', priority: 1)
                create(:word_code, identifier: 'V12', code: '310001', name1: '失')
                create(:word_code, identifier: 'V12', code: '120000', name1: '落')
              end
            end
          end

          hold_player = HoldPlayer.find_by(hold: hold, player: player)
          hold_player.update(last_hold_player: last_hold_player)
        end

        it 'レスポンスに前回成績が設定されていること' do
          get_race_detail
          json = JSON.parse(response.body)
          expect(json['data']['race_table'][0]['last_round_result']['promoter_year']).to eq promoter_year
          expect(json['data']['race_table'][0]['last_round_result']['season']).to eq period
          expect(json['data']['race_table'][0]['last_round_result']['round_code']).to eq round
          expect(json['data']['race_table'][0]['last_round_result']['event_date']).to eq first_day.strftime('%Y-%m-%d')
          expect(json['data']['race_table'][0]['last_round_result']['tt_record']).to eq total_time
          expect(json['data']['race_table'][0]['last_round_result']['tt_rank']).to eq tt_rank

          expect(json['data']['race_table'][0]['last_round_result']['race_list'][0]['event_code']).to eq event_code[1]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][0]['details_code']).to eq details_code[1]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][0]['race_rank']).to eq race_rank[1].to_s

          expect(json['data']['race_table'][0]['last_round_result']['race_list'][1]['event_code']).to eq event_code[0]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][1]['details_code']).to eq details_code[0]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][1]['race_rank']).to eq race_rank[0].to_s

          expect(json['data']['race_table'][0]['last_round_result']['race_list'][2]['event_code']).to eq event_code[2]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][2]['details_code']).to eq details_code[2]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][2]['race_rank']).to eq race_rank[2].to_s

          expect(json['data']['race_table'][0]['last_round_result']['race_list'][3]['event_code']).to eq event_code[3]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][3]['details_code']).to eq details_code[3]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][3]['race_rank']).to eq race_rank[3].to_s

          expect(json['data']['race_table'][0]['last_round_result']['race_list'][4]['event_code']).to eq event_code[4]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][4]['details_code']).to eq details_code[4]
          expect(json['data']['race_table'][0]['last_round_result']['race_list'][4]['race_rank']).to eq '失'
        end

        context 'event_codeがW X Yの場合' do
          let(:race_id) { race.id }

          before { RaceDetail.update_all(event_code: %w[W X Y].sample) }

          it 'race_tableのlast_round_resultのrace_listのevent_codeはTを返すこと' do
            get_race_detail
            json = JSON.parse(response.body)
            expect(json['data']['race_table'][0]['last_round_result']['race_list'][0]['event_code']).to eq 'T'
          end
        end
      end

      it 'レスポンスパラメータのキーが正しいこと' do
        get_race_detail
        json = JSON.parse(response.body)
        data_keys = %w[hold_daily_schedule race_table race_movie_yt_id interview_movie_yt_id payoff_list]
        expect(data_keys).to include_keys(json['data'].keys)

        race_table_keys = %w[bike_no cancel tt_time tt_rank odds race_time race_rank player]
        expect(race_table_keys).to include_keys(json['data']['race_table'][0].keys)

        payoff_list_keys = %w[payoff_type vote_type tip1 tip2 tip3]
        expect(payoff_list_keys).to include_keys(json['data']['payoff_list'][0].keys)
      end
    end

    context '複数のodds_infoがある場合' do
      # rubocop:disable RSpec/LetSetup
      let!(:race) { create(:race) }
      let!(:player) { create(:player, pf_player_id: 999, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join) }
      let!(:race_detail) { create(:race_detail, race: race) }
      let!(:race_player_1) { create(:race_player, race_detail: race_detail, bike_no: 1, pf_player_id: player.pf_player_id) }
      let!(:race_player_2) { create(:race_player, race_detail: race_detail, bike_no: 2, pf_player_id: player.pf_player_id) }
      # odds_timeの異なる複数のodds_info
      let!(:old_odds_info) { create(:odds_info, race_detail: race_detail, odds_time: '2021-01-01 10:00:00') }
      let!(:latest_odds_info) { create(:odds_info, race_detail: race_detail, odds_time: '2021-01-01 10:01:00') }
      # それぞれのodds_infoに対する4odds_list
      let!(:old_odds_list_win) { create(:odds_list, odds_info: old_odds_info, vote_type: 10) }
      let!(:old_odds_list_place) { create(:odds_list, odds_info: old_odds_info, vote_type: 20) }
      let!(:latest_odds_list_win) { create(:odds_list, odds_info: latest_odds_info, vote_type: 10) }
      let!(:latest_odds_list_place) { create(:odds_list, odds_info: latest_odds_info, vote_type: 20) }
      # それぞれのodds_listに対するodds_detail
      let!(:old_odds_detail_win_1) { create(:odds_detail, odds_list: old_odds_list_win, tip1: race_player_1.bike_no) }
      let!(:old_odds_detail_win_2) { create(:odds_detail, odds_list: old_odds_list_win, tip1: race_player_2.bike_no) }
      let!(:old_odds_detail_place_1) { create(:odds_detail, odds_list: old_odds_list_place, tip1: race_player_1.bike_no) }
      let!(:old_odds_detail_place_2) { create(:odds_detail, odds_list: old_odds_list_place, tip1: race_player_2.bike_no) }
      let!(:latest_odds_detail_win_1) { create(:odds_detail, odds_list: latest_odds_list_win, tip1: race_player_1.bike_no, odds_val: 1000.0) }
      let!(:latest_odds_detail_win_2) { create(:odds_detail, odds_list: latest_odds_list_win, tip1: race_player_2.bike_no, odds_val: 3.3) }
      let!(:latest_odds_detail_place_1) { create(:odds_detail, odds_list: latest_odds_list_place, tip1: race_player_1.bike_no, odds_val: 50.3) }
      let!(:latest_odds_detail_place_2) { create(:odds_detail, odds_list: latest_odds_list_place, tip1: race_player_2.bike_no, odds_val: 100.5) }
      # rubocop:enable RSpec/LetSetup

      before do
        create(:hold_player, hold: race.hold_daily_schedule.hold_daily.hold, player_id: player.id)
        create(:player_original_info, player_id: player.id, pf_250_regist_id: 20, speed: 5, stamina: 1, power: 2, technique: 3, mental: 4, evaluation: 99, round_best: 'mm:ss.MMMM', year_best: 'mm:ss.MMMM',
                                      major_title: 'test', pist6_title: 'bb', last_name_en: player.name_en, first_name_en: player.name_en)
      end

      it 'oddsは最新の単勝オッズを返す' do
        get v1_mt_datas_race_details_url, params: { race_id: race.id }
        json = JSON.parse(response.body)
        expect(json['data']['race_table'][0]['odds']).to eq(latest_odds_detail_win_1.odds_val)
      end
    end

    context 'race_detailがない場合' do
      let!(:race_2) { create(:race) }
      let(:race_id) { race_2.id }

      it 'レスポンスパラメータがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'race_playersの必須のパラメータがない場合' do
      let!(:race_2) { create(:race, :with_bike_no_nil_race_player) }
      let(:race_id) { race_2.id }

      it 'レスポンスパラメータがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'payoff_listの必須のパラメータがない場合' do
      let(:race_2) { create(:race, :with_payoff_type_nil) }
      let(:race_3) { create(:race, :with_vote_type_nil) }

      it 'payoff_typeがnilのpayoff_listは取得できないこと' do
        get v1_mt_datas_race_details_url(race_id: race_2.id)
        json = JSON.parse(response.body)
        expect(json['data']['payoff_list']).to eq([])
      end

      it 'vote_typeがnilのpayoff_listは取得できないこと' do
        get v1_mt_datas_race_details_url(race_id: race_3.id)
        json = JSON.parse(response.body)
        expect(json['data']['payoff_list']).to eq([])
      end
    end

    context 'RacePlayerのbike_noがnilの場合' do
      let(:race_id) { race.id }

      before do
        race.race_detail.race_players.first.update(bike_no: nil)
      end

      it 'レスポンスパラメータがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'PlayerOriginalInfoのlast_name_enがnilの場合' do
      let(:race_id) { race.id }

      before do
        race_player_pf_player_id = race.race_detail.race_players.first.pf_player_id
        Player.find_by(pf_player_id: race_player_pf_player_id).player_original_info.update_column(:last_name_en, nil)
      end

      it 'レスポンスパラメータがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'PlayerOriginalInfoのfirst_name_enがnilの場合' do
      let(:race_id) { race.id }

      before do
        race_player_pf_player_id = race.race_detail.race_players.first.pf_player_id
        Player.find_by(pf_player_id: race_player_pf_player_id).player_original_info.update_column(:first_name_en, nil)
      end

      it 'レスポンスパラメータがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'PlayerOriginalInfoのpf_250_regist_idがnilの場合' do
      let(:race_id) { race.id }

      before do
        race_player_pf_player_id = race.race_detail.race_players.first.pf_player_id
        Player.find_by(pf_player_id: race_player_pf_player_id).player_original_info.update_column(:pf_250_regist_id, nil)
      end

      it 'レスポンスパラメータがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']).to eq(nil)
      end
    end

    context 'odds_infoがない場合' do
      # rubocop:disable RSpec/LetSetup
      let!(:race) { create(:race) }
      let!(:player) { create(:player, pf_player_id: 999, name_en: (0...8).map { ('A'..'Z').to_a[rand(26)] }.join) }
      let!(:race_detail) { create(:race_detail, race: race) }
      let!(:race_player_1) { create(:race_player, race_detail: race_detail, bike_no: 1, pf_player_id: player.pf_player_id) }
      let!(:race_player_2) { create(:race_player, race_detail: race_detail, bike_no: 2, pf_player_id: player.pf_player_id) }
      # rubocop:enable RSpec/LetSetup

      before do
        create(:hold_player, hold: race.hold_daily_schedule.hold_daily.hold, player_id: player.id)
        create(:player_original_info, player_id: player.id, pf_250_regist_id: 20, speed: 5, stamina: 1, power: 2, technique: 3, mental: 4, evaluation: 99, round_best: 'mm:ss.MMMM', year_best: 'mm:ss.MMMM',
                                      major_title: 'test', pist6_title: 'bb', last_name_en: player.name_en, first_name_en: player.name_en)
      end

      it 'oddsはnilを返すこと' do
        get v1_mt_datas_race_details_url, params: { race_id: race.id }
        json = JSON.parse(response.body)
        expect(json['data']['race_table'][0]['odds']).to be_nil
      end
    end

    context '2021/10/11以降のレースの場合、' do
      let!(:race) { create(:race) }
      let!(:race_detail) { create(:race_detail, race: race, hold_day: '20211011') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:race_player) { create(:race_player, race_detail: race_detail, pf_player_id: player.pf_player_id, bike_no: 1, start_position: 3) }
      let(:race_id) { race.id }

      before do
        create(:player_original_info, player: player, first_name_en: 'Tiger', last_name_en: 'Woods', pf_250_regist_id: '123456')
      end

      it 'start_positionはレコードの値を返す' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']['race_table'][0]['start_position']).to eq(race_player.start_position)
      end
    end

    context '2021/10/11より前のレース場合、' do
      let!(:race) { create(:race) }
      let!(:race_detail) { create(:race_detail, race: race, hold_day: '20211010') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let(:race_id) { race.id }

      before do
        create(:player_original_info, player: player, first_name_en: 'Tiger', last_name_en: 'Woods', pf_250_regist_id: '123456')
        create(:race_player, race_detail: race_detail, pf_player_id: player.pf_player_id, bike_no: 1, start_position: 3)
      end

      it 'start_positionはnullを返す' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']['race_table'][0]['start_position']).to eq(nil)
      end
    end

    context 'tt_timeが99.9999の場合' do
      let(:race_id) { race.id }

      before do
        TimeTrialPlayer.update(total_time: 99.9999)
      end

      it 'tt_timeがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']['race_table'][0]['tt_time']).to eq(nil)
      end
    end

    context 'tt_timeが99.999の場合' do
      let(:race_id) { race.id }

      before do
        TimeTrialPlayer.update(total_time: 99.999)
      end

      it 'tt_timeがnilで返ってくること' do
        get_race_detail
        json = JSON.parse(response.body)
        expect(json['data']['race_table'][0]['tt_time']).to eq(nil)
      end
    end
  end

  describe 'GET /search_sort_items' do
    subject(:get_search_sort_items) { get v1_mt_datas_search_sort_items_url }

    before do
      create_list(:player_original_info, 10)
    end

    it 'レスポンスパラメータの長さが想定どおりであること' do
      PlayerOriginalInfo.first.update(free2: nil)
      PlayerOriginalInfo.last.update(last_name_en: nil)
      PlayerOriginalInfo.last.update(evaluation: nil)
      get_search_sort_items
      json = JSON.parse(response.body)
      expect(json['data']['country'].length).to eq(PlayerOriginalInfo.pluck(:free2).compact.uniq.length)
      expect(json['data']['initial'].length).to eq(PlayerOriginalInfo.pluck(:last_name_en).compact.map(&:first).uniq.length)
      expect(json['data']['evaluation'].length).to eq(PlayerOriginalInfo.pluck(:evaluation).compact.uniq.length)
    end

    it 'レスポンスパラメータが想定どおり返ってきていること' do
      get_search_sort_items
      json = JSON.parse(response.body)
      target_player = PlayerOriginalInfo.all.sample

      expect(json['data']['country'].find { |arr| arr.first == target_player.free2 }.last).to eq(PlayerOriginalInfo.pluck(:free2).count { |fr| fr == target_player.free2 })
      expect(json['data']['initial'].find { |arr| arr.first == target_player.last_name_en.first }.last).to eq(PlayerOriginalInfo.pluck(:last_name_en).compact.map(&:first).count { |n| n == target_player.last_name_en.first })
      expect(json['data']['evaluation'].find { |arr| arr.first == 'C' }.last).to eq(PlayerOriginalInfo.pluck(:evaluation).count { |ev| ev == 10 })
    end

    it '総合評価のレスポンスパラメータが想定どおり返ってきていること' do
      PlayerOriginalInfo.second.update(evaluation: 300)
      PlayerOriginalInfo.third.update(evaluation: 400)
      PlayerOriginalInfo.fourth.update(evaluation: 500)
      get_search_sort_items
      json = JSON.parse(response.body)
      expect(json['data']['evaluation'].find { |arr| arr.first == 'C' }.last).to eq(PlayerOriginalInfo.pluck(:evaluation).count { |ev| ev == 10 })
    end
  end

  describe 'GET /scheduled_seasons' do
    subject(:get_scheduled_seasons) { get v1_mt_datas_scheduled_seasons_url }

    let!(:last_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now) - 1, season: 'last_year_promoter_year_title', first_day: Time.zone.now.prev_year(1), period: 'wildcard') }

    context '2日前より未来に対象のholdがある場合' do
      let!(:this_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.next_day(1), period: 'summer') }
      let!(:next_promoter_year_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now) + 1, season: 'next_year_promoter_year_title', first_day: Time.zone.now.next_year(1), period: 'spring') }

      before do
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.next_day(7), period: 'summer')
        create(:hold, promoter_year: fiscal_year(Time.zone.now) + 2, season: 'year_after_next_promoter_year_title', first_day: Time.zone.now.next_year(2), period: 'autumn')
      end

      it '対象のデータが最大２配列で返されること' do
        get_scheduled_seasons
        json = JSON.parse(response.body)
        expect(json['data']['scheduled_seasons'][0]['promoter_year']).to eq(this_promoter_year_hold.promoter_year)
        expect(json['data']['scheduled_seasons'][0]['season']).to eq(this_promoter_year_hold.period)
        expect(json['data']['scheduled_seasons'][1]['promoter_year']).to eq(next_promoter_year_hold.promoter_year)
        expect(json['data']['scheduled_seasons'][1]['season']).to eq(next_promoter_year_hold.period)
        expect(json['data']['scheduled_seasons'][2]).to eq(nil)
      end
    end

    context '開催初日が3日前の開催が最新で、将来の開催がない場合' do
      before do
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(10), period: 'summer', round: 1)
      end

      let!(:recent_past_hold) { create(:hold, promoter_year: fiscal_year(Time.zone.now), season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(3), period: 'spring', round: 1) }

      it '対象のデータが返されること' do
        get_scheduled_seasons
        json = JSON.parse(response.body)
        expect(json['data']['scheduled_seasons'][0]['promoter_year']).to eq(recent_past_hold.promoter_year)
        expect(json['data']['scheduled_seasons'][0]['season']).to eq(recent_past_hold.period)
      end
    end

    context 'promoter_yearがnilのデータがある場合' do
      before do
        create(:hold, promoter_year: nil, season: 'this_year_promoter_year_title', first_day: Time.zone.now.prev_day(30), period: 2)
      end

      it 'promoter_yearがnilではないデータしか取得していないこと' do
        get_scheduled_seasons
        json = JSON.parse(response.body)
        expect(json['data']['scheduled_seasons'][0]['promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['scheduled_seasons'][0]['season']).to eq(last_promoter_year_hold.period)
        expect(json['data']['scheduled_seasons'][1]).to eq nil
      end
    end

    context 'periodがnilのデータがある場合' do
      before do
        create(:hold, promoter_year: fiscal_year(Time.zone.now), season: '決定戦2-n', first_day: Time.zone.now.prev_day(30), period: nil)
      end

      it 'periodがnilではないデータのみ取得すること' do
        get_scheduled_seasons
        json = JSON.parse(response.body)
        expect(json['data']['scheduled_seasons'][0]['promoter_year']).to eq(last_promoter_year_hold.promoter_year)
        expect(json['data']['scheduled_seasons'][0]['season']).to eq(last_promoter_year_hold.period)
        expect(json['data']['scheduled_seasons'][1]).to eq nil
      end
    end

    context '対象のデータがない場合' do
      before do
        Hold.delete_all
      end

      it '正常に終了して空配列が返ること' do
        get_scheduled_seasons
        json = JSON.parse(response.body)
        expect(json['data']['scheduled_seasons'][0]).to eq nil
      end
    end
  end

  describe 'GET /races_revision' do
    subject(:get_races_revision) { get v1_mt_datas_races_revision_url, params: params }

    let(:params) { { hold_daily_schedule_id_list: [hold_daily.hold_daily_schedules.first.id] } }
    let(:hold) { create(:hold, promoter_year: Time.zone.now.year, period: 1, round: 1) }
    let(:hold_daily) { create(:hold_daily, :with_final_race, hold: hold) }
    let!(:hold_daily_schedule) { hold_daily.hold_daily_schedules.first }

    before do
      hold_daily_schedule.races.update(details_code: 'F1')
      create(:race_result, entries_id: '111111', race_detail: hold_daily_schedule.races.first.race_detail)
    end

    context '取得成功' do
      it 'レスポンスパラメータの確認' do
        race_pf_player = hold_daily_schedule.races.first.race_detail.race_players.first
        race_pf_250_regist_id = Player.find_by(pf_player_id: race_pf_player.pf_player_id).pf_250_regist_id
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule.id)
        expect(json['data'][0]['race_list'][0]['id']).to eq(hold_daily_schedule.races.first.id)
        expect(json['data'][0]['race_list'][0]['race_no']).to eq(hold_daily_schedule.races.first.race_no)
        expect(json['data'][0]['race_list'][0]['event_date']).to eq(hold_daily.event_date.strftime('%Y-%m-%d'))
        expect(json['data'][0]['race_list'][0]['day_night']).to eq(hold_daily_schedule.daily_no_before_type_cast)
        expect(json['data'][0]['race_list'][0]['post_time']).to eq(time_format(hold_daily_schedule.races.first.post_time))
        expect(json['data'][0]['race_list'][0]['name']).to eq(hold_daily_schedule.races.first.event_code)
        expect(json['data'][0]['race_list'][0]['detail']).to eq(hold_daily_schedule.races.first.details_code)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(3)
        expect(json['data'][0]['race_list'][0]['player_list'][0]['player']['id']).to eq(race_pf_250_regist_id)
        expect(json['data'][0]['race_list'][0]['player_list'][0]['bike_no']).to eq(race_pf_player.bike_no)
        expect(json['data'][0]['race_list'][0]['player_list'].size).to eq(hold_daily_schedule.races.first.race_detail.race_players.size)
      end
    end

    context '出走表がなく、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは2になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.destroy
        hold.update(hold_status: [*2..9].sample)
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(2)
      end
    end

    context '出走表がなく、開催が終了していない場合（hold_statusが0、1の場合）、対象のrace_listのcancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.destroy
        hold.update(hold_status: [0, 1].sample)
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context 'race_statusが0またはnilで、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: ['0', nil].sample)
        hold.update(hold_status: [*2..9].sample)
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context 'race_statusが0またはnilで、開催が終了していない場合（hold_statusが0、1の場合））、対象のrace_listのcancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: ['0', nil].sample)
        hold.update(hold_status: [0, 1].sample)
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context 'race_statusが0,10,15,nil以外の場合、cancel_statusは2になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: '20')
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(2)
      end
    end

    context 'race_statusが0,10,15,nilの場合、cancel_statusは1になること' do
      it ' レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.update(race_status: ['0', '10', '15', nil].sample)
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
      end
    end

    context '出走表がない場合、対象のrace_listのrace_statusは1になること' do
      it 'レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.destroy
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
      end
    end

    context '出走選手がない場合、対象のrace_listのrace_statusは1になること' do
      it 'レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.race_players.destroy_all
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
      end
    end

    context '出走表、出走選手はあるが、レース結果がない場合、対象のrace_listのrace_statusは2になること' do
      it 'レスポンスパラメータの確認' do
        hold_daily_schedule.races.first.race_detail.race_result.destroy
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['race_status']).to eq(2)
      end
    end

    context 'params指定しない場合' do
      let(:params) { nil }
      let(:hold_daily) { create(:hold_daily, :with_final_race, event_date: Time.zone.now + 1.day, hold: hold) }

      it '開催前のレースがある場合、リクエスト日以降で開始前のレースを含む最初の販売情報をベースにして取得する' do
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule.id)
      end

      it '開催前のレースがない場合、最後の販売情報を取得する' do
        create(:race_result, race_detail: hold_daily_schedule.races.first.race_detail)
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['hold_daily_schedule']['id']).to eq(hold_daily_schedule.id)
      end
    end

    context 'params指定無しで、開催前のレースがある場合' do
      let(:params) { nil }
      let(:hold_daily) { create(:hold_daily, :with_final_race, event_date: Time.zone.now + 1.day, hold: hold) }

      it 'promoter_yearがnilの場合、取得できないこと' do
        hold.update(promoter_year: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'roundがnilの場合、取得できないこと' do
        hold.update(round: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'periodがnilの場合、取得できないこと' do
        hold.update(period: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'details_codeがnilの場合、取得できないこと' do
        hold_daily_schedule.races.update(details_code: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end
    end

    context 'params指定無しで、開催前のレースがない場合' do
      let(:params) { nil }
      let(:hold_daily) { create(:hold_daily, :with_final_race, event_date: Time.zone.now + 1.day, hold: hold) }
      let(:race_result) { create(:race_result, race_detail: hold_daily_schedule.races.first.race_detail) }

      it 'promoter_yearがnilの場合、取得できないこと' do
        race_result
        hold.update(promoter_year: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'roundがnilの場合、取得できないこと' do
        race_result
        hold.update(round: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'periodがnilの場合、取得できないこと' do
        race_result
        hold.update(period: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'details_codeがnilの場合、取得できないこと' do
        race_result
        hold_daily_schedule.races.update(details_code: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end
    end

    context '出走表あるいは出走表に選手が入っていない場合' do
      let(:hold_daily_3) { create(:hold_daily, hold: hold) }
      let(:hold_daily_schedule_3) { create(:hold_daily_schedule, hold_daily: hold_daily_3) }
      let!(:race) { create(:race, hold_daily_schedule: hold_daily_schedule_3, details_code: 'F1') }
      let(:params) { { hold_daily_schedule_id_list: [hold_daily_schedule_3.id] } }

      context '出走表がなく、開催が終了していた場合（hold_statusが0、1以外の場合）、対象のrace_listのcancel_statusは2になること' do
        it ' レスポンスパラメータの確認' do
          hold.update(hold_status: [*2..9].sample)
          get_races_revision
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(2)
        end
      end

      context '出走表がなく、開催が終了していない場合（hold_statusが0、1の場合）、対象のrace_listのcancel_statusは1になること' do
        it ' レスポンスパラメータの確認' do
          hold.update(hold_status: [0, 1].sample)
          get_races_revision
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['cancel_status']).to eq(1)
        end
      end

      context '出走表がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.destroy
          get_races_revision
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走選手がない場合、対象のrace_listのrace_statusは1になること' do
        it 'レスポンスパラメータの確認' do
          hold_daily_schedule.races.first.race_detail.race_players.destroy_all
          get_races_revision
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['race_status']).to eq(1)
        end
      end

      context '出走表、出走選手はあるが、レース結果がない場合、対象のrace_listのrace_statusは2になること' do
        let!(:race_detail) { create(:race_detail, race: race) }

        it 'レスポンスパラメータの確認' do
          create(:race_player, race_detail: race_detail)
          get_races_revision
          json = JSON.parse(response.body)
          expect(json['data'][0]['race_list'][0]['race_status']).to eq(2)
        end
      end
    end

    context '必須のパラメータがない場合' do
      it 'promoter_yearがnilの場合、取得できないこと' do
        hold.update(promoter_year: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'roundがnilの場合、取得できないこと' do
        hold.update(round: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'periodがnilの場合、取得できないこと' do
        hold.update(period: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end

      it 'details_codeがnilの場合、取得できないこと' do
        hold_daily_schedule.races.update(details_code: nil)
        get_races_revision
        expect(JSON.parse(response.body)['data']).to be_blank
      end
    end

    context 'event_codeがWの場合' do
      it 'raceのevent_codeがWの場合、nameでTを返すこと' do
        hold_daily_schedule.races.first.update(event_code: 'W')
        get_races_revision
        json = JSON.parse(response.body)
        expect(json['data'][0]['race_list'][0]['name']).to eq('T')
      end
    end
  end
end
