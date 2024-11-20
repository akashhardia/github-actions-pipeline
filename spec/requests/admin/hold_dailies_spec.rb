# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HoldDailiesScheduleController', :admin_logged_in, type: :request do
  let(:hold) { create(:hold, pf_hold_id: '1') }
  let(:hold_daily) { create(:hold_daily, hold: hold) }

  describe 'GET /admin/hold_dailies' do
    subject(:get_hold_dailies) { get admin_hold_dailies_url, params: { hold_id: hold_daily.hold.id } }

    it 'HTTPステータスが200であること' do
      get_hold_dailies
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json[0].keys).to match_array(::HoldDailyIndexSerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end
  end

  describe 'GET /admin/hold_dailies/calendar' do
    subject(:hold_daily_calendar) { get admin_hold_dailies_calendar_url(format: :json, params: params) }

    let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily_id: hold_daily.id) }
    let(:hold_daily) { create(:hold_daily, event_date: event_date) }
    let(:event_date) { Time.zone.today }

    context '開催が存在する年・月を指定した場合' do
      before do
        create_list(:seat_sale, 3, :available, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      let(:params) { { year: hold_daily.event_date.year, month: hold_daily.event_date.month } }

      it 'HTTPステータスが200であること' do
        hold_daily_calendar
        expect(response).to have_http_status(:ok)
      end

      it '期間内の開催デイリーが取得できること' do
        hold_daily_calendar
        json = JSON.parse(response.body)
        expect(json[0]['id']).to eq(hold_daily.id)
      end

      context '販売情報が含まれている場合' do
        it '販売情報のデータも入っていること' do
          hold_daily_calendar
          json = JSON.parse(response.body)
          expect(json[0]['holdDailySchedules'][0]['seatSales'].present?).to be true
        end
      end
    end

    context 'seat_saleが0件の開催の場合' do
      let(:params) { { year: hold_daily.event_date.year, month: hold_daily.event_date.month } }

      it '空の配列が返ってくること' do
        hold_daily_calendar
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end

    context 'paramsがない場合' do
      before do
        create_list(:seat_sale, 3, :available, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      it '現在の年・月で開催デイリーが検索されること' do
        expect_id = hold_daily.id
        hold_daily_calendar
        json = JSON.parse(response.body)
        expect(json[0]['id']).to eq(expect_id)
      end
    end

    context '月の境界値を指定した場合' do
      before do
        create_list(:seat_sale, 3, :available, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      let(:params) { { year: hold_daily.event_date.year, month: hold_daily.event_date.month } }

      context '2020-04-01' do
        let(:event_date) { '2020-04-01' }

        it '期間内の開催デイリーが取得できること' do
          hold_daily_calendar
          json = JSON.parse(response.body)
          expect(json[0]['id']).to eq(hold_daily.id)
        end
      end

      context '2020-04-30' do
        let(:event_date) { '2020-04-30' }

        it '期間内の開催デイリーが取得できること' do
          hold_daily_calendar
          json = JSON.parse(response.body)
          expect(json[0]['id']).to eq(hold_daily.id)
        end
      end
    end

    context '開催が存在しない年・月を指定した場合' do
      before do
        create_list(:seat_sale, 3, :available, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      let(:params) { { year: 1900, month: 1 } }

      it '空の配列が返ってくること' do
        hold_daily_calendar
        json = JSON.parse(response.body)
        expect(json).to eq([])
      end
    end
  end

  describe 'GET /admin/hold_dailies/:id' do
    subject(:get_hold_daily) { get admin_hold_daily_url(hold_daily.id) }

    it 'HTTPステータスが200であること' do
      get_hold_daily
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::CouponSerializerの属性を持つハッシュであること' do
      get_hold_daily
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(::HoldDailySerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end
  end

  describe 'GET /hold_dailies/:id/movie_ids' do
    subject(:movie_ids) { get movie_ids_admin_hold_daily_url(hold_daily_id, format: :json) }

    let(:hold_daily_id) { hold_daily_schedule_am.hold_daily.id }
    let(:hold_daily_schedule_am) { create(:hold_daily_schedule) }
    let(:hold_daily_schedule_pm) { create(:hold_daily_schedule, hold_daily: hold_daily_schedule_am.hold_daily, daily_no: 1) }

    before do
      1.upto(6) { |n| create(:race, race_no: n, hold_daily_schedule: hold_daily_schedule_am) }
      7.upto(12) { |n| create(:race, race_no: n, hold_daily_schedule: hold_daily_schedule_pm) }
    end

    it 'HTTPステータスが200であること' do
      movie_ids
      expect(response).to have_http_status(:ok)
    end

    it 'jsonはRaceMovieIdSerializerの属性を持つハッシュであること' do
      movie_ids
      json = JSON.parse(response.body)
      expect(json.length).to eq(12)
      expect(json[0].keys).to match_array(::RaceMovieIdSerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end

    context 'ないIDを指定した場合はnot_foundエラーが返ること' do
      let(:hold_daily_id) { 9999 }

      it '404が返ること' do
        movie_ids
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT /hold_dailies/:id/movie_ids' do
    subject(:movie_ids_update) { put movie_ids_update_admin_hold_daily_url(hold_daily_id, format: :json), params: params }

    let(:hold_daily_id) { hold_daily_schedule_am.hold_daily.id }
    let(:hold_daily_schedule_am) { create(:hold_daily_schedule) }
    let(:hold_daily_schedule_pm) { create(:hold_daily_schedule, hold_daily: hold_daily_schedule_am.hold_daily, daily_no: 1) }
    let(:params) do
      1.upto(6) { |n| create(:race, race_no: n, hold_daily_schedule: hold_daily_schedule_am) }
      7.upto(12) { |n| create(:race, race_no: n, hold_daily_schedule: hold_daily_schedule_pm) }
      {
        raceList: Race.all.map { |race| { id: race.id, race_movie_yt_id: 'race_url', interview_movie_yt_id: 'interview_url' } }
      }
    end

    it 'HTTPステータスが200であること' do
      movie_ids_update
      expect(response).to have_http_status(:ok)
    end

    it 'raceのrace_movie_yt_id, interview_movie_yt_idが更新されること' do
      race = Race.first
      race.update(race_movie_yt_id: 'before_url', interview_movie_yt_id: 'before_url')
      expect { movie_ids_update }.to change { Race.find(race.id).race_movie_yt_id }
        .from('before_url').to('race_url').and change { Race.find(race.id).interview_movie_yt_id }
        .from('before_url').to('interview_url')
    end
  end
end
