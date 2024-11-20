# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notification', type: :request do
  include AuthenticationHelper

  describe 'POST /odds' do
    subject(:odds_create) { post v1_notifications_odds_url, params: params, headers: access_token }

    let(:entries_id) { create(:race_detail).entries_id }
    let(:params) do
      {
        "entries_id": entries_id,
        "odds_time": '2021/02/21',
        "fixed": 'false',
        "odds_list": [
          {
            "vote_type": 10,
            "odds_count": 10,
            "odds": [
              {
                "tip1": '1',
                "tip2": '2',
                "tip3": '3',
                "odds_val": '5.1',
                "odds_max_val": '10.1'
              },
              {
                "tip1": '2',
                "tip2": '1',
                "tip3": '3',
                "odds_val": '15.1',
                "odds_max_val": '110.1'
              }
            ]
          },
          {
            "vote_type": 20,
            "odds_count": 10,
            "odds": [
              {
                "tip1": '1',
                "tip2": '2',
                "tip3": '3',
                "odds_val": '5.1',
                "odds_max_val": '10.1'
              }
            ]
          }
        ]
      }
    end

    context '成功する場合' do
      it 'result_code 100が返ってくること' do
        expect { odds_create }.to change(OddsInfo, :count).by(1).and change(OddsList, :count).by(2).and change(OddsDetail, :count).by(3)
        json = JSON.parse(response.body)
        expect(json['result_code']).to eq(100)
      end
    end

    context 'entries_idに該当するrace_detailがない場合' do
      let(:entries_id) { 9999 }

      it 'result_code 600が返ってくること' do
        odds_create
        json = JSON.parse(response.body)
        expect(json['result_code']).to eq(600)
      end
    end
  end

  describe 'POST /vote' do
    subject(:vote_notification) { post v1_notifications_vote_url, params: params, headers: access_token }

    let(:race_detail) { create(:race_detail) }
    let(:entries_id) { race_detail.entries_id }
    let(:pf_hold_id) { race_detail.pf_hold_id }
    let(:hold_id_daily) { race_detail.hold_id_daily }
    let(:close_time) { '2021-02-25 17:00:00 +0900' }
    let(:params) do
      {
        "status": 100,
        "hold_id": pf_hold_id,
        "hold_id_daily": hold_id_daily,
        "entries_id_list": [
          {
            "entries_id": entries_id,
            "race_no": 10,
            "close_time": close_time
          }
        ]
      }
    end

    context '成功する場合' do
      it 'result_code 100が返ってくること' do
        expect { vote_notification }.to change { RaceDetail.find(race_detail.id).close_time.to_s }.from('').to(close_time)
        json = JSON.parse(response.body)
        expect(json['result_code']).to eq(100)
      end
    end

    context 'entries_idに該当するrace_detailがない場合' do
      let(:entries_id) { 9999 }

      it 'result_code 600が返ってくること' do
        vote_notification
        json = JSON.parse(response.body)
        expect(json['result_code']).to eq(600)
      end
    end
  end

  describe 'POST /payoff' do
    subject(:payoff_create) { post v1_notifications_payoff_url, params: params, headers: access_token }

    let(:entries_id) { create(:race_detail).entries_id }
    let(:params) do
      {
        "entries_id": entries_id,
        "race_status": '10',
        "rank": [
          '3,4',
          '',
          '2',
          '1'
        ],
        "payoff_list": [
          {
            "payoff_type": 10,
            "vote_type": 10,
            "tip1": '3,4',
            "tip2": '',
            "tip3": '2',
            "payoff": '10000'
          },
          {
            "payoff_type": 10,
            "vote_type": 20,
            "tip1": '3,4',
            "tip2": '',
            "tip3": '2',
            "payoff": '1000'
          }
        ]
      }
    end

    context '成功する場合' do
      it 'result_code 100が返ってくること' do
        expect { payoff_create }.to change(PayoffList, :count).by(2).and change(Rank, :count).by(4)
        json = JSON.parse(response.body)
        expect(json['result_code']).to eq(100)
      end
    end

    context 'entries_idに該当するrace_detailがない場合' do
      let(:entries_id) { 9999 }

      it 'result_code 600が返ってくること' do
        payoff_create
        json = JSON.parse(response.body)
        expect(json['result_code']).to eq(600)
      end
    end
  end

  describe 'GET /holding' do
    subject(:notifications_holding) { post v1_notifications_holding_url(params: notification_params, format: :json) }

    let(:empty_hold_id) { 100 }
    let(:hold_id) { 10 }
    let(:update_hold_id) { 110 }
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }
    let(:hold_daily) { create(:hold_daily, hold: hold) }
    let(:hold) { create(:hold, pf_hold_id: '1') }

    context 'type_idが1だった場合' do
      before do
        create(:race, hold_daily_schedule: hold_daily_schedule, program_no: 1)
      end

      context 'hold_idがnilだった場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => nil }
            ]
          }
        end

        it 'result_code 600が返ること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end

      context 'hold_idがはあるがリストが取得できなかった場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => 'hold_id', 'value' => empty_hold_id }
            ]
          }
        end

        it 'result_code 600が返ること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end

      context 'pf_hold_idがparamsのhold_idであるholdがない場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id }
            ]
          }
        end

        it 'hold,hold_daily,raceが作成され、result_code 100が返ること' do
          expect { notifications_holding }
            .to change { Hold.find_by(pf_hold_id: hold_id).present? }
            .from(false).to(true)
            .and change(Hold, :count).by(1)
                                     .and change(HoldDaily, :count).by(2)
                                                                   .and change(Race, :count).by(10)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end
      end

      context 'pf_hold_idが引数のhold_idであるholdがある場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id }
            ]
          }
        end

        before do # 事前に作成して、値を変更してupdateをかけて元に戻るかの検証
          PlatformSync.hold_update!(hold_id: hold_id)
          hold = Hold.find_by(pf_hold_id: 10)
          hold.update(hold_name_jp: '間違った開催')
          hold_daily = hold.hold_dailies.find_by(hold_id_daily: 241)
          hold_daily.update(race_count: 4)
          hold_daily.races.each { |race| race.update(race_distance: 500) }
        end

        it 'hold,hold_daily,raceが更新されること' do
          hold_daily = Hold.find_by(pf_hold_id: 10).hold_dailies.find_by(hold_id_daily: 241)
          before_race_distances = Array.new(10, 500)
          after_race_distances = Array.new(9, 1020) << 1500

          expect { notifications_holding }
            .to change { Hold.find_by(pf_hold_id: 10).hold_name_jp }
            .from('間違った開催').to('川崎開催テスト２')
            .and change { HoldDaily.find(hold_daily.id).race_count }
            .from(4).to(9)
            .and change { hold_daily.races.order(:program_no).pluck(:race_distance) }
            .from(before_race_distances).to(after_race_distances)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end
      end

      context '引数のhold_idが複数あり全て正常に処理できる場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id },
              { 'key' => 'hold_id', 'value' => update_hold_id }
            ]
          }
        end

        before do # 事前に作成して、値を変更してupdateをかけて元に戻るかの検証
          PlatformSync.hold_update!(hold_id: update_hold_id)
          hold = Hold.find_by(pf_hold_id: 110)
          hold.update(hold_name_jp: '間違った開催')
          hold_daily = hold.hold_dailies.find_by(hold_id_daily: 241)
          hold_daily.update(race_count: 4)
          hold_daily.races.each { |race| race.update(race_distance: 500) }
        end

        it '想定通りhold,hold_daily,raceが作成され、result_code 100が返ること' do
          expect { notifications_holding }
            .to change { Hold.find_by(pf_hold_id: hold_id).present? }
            .from(false).to(true)
            .and change(Hold, :count).by(1)
                                     .and change(HoldDaily, :count).by(2)
                                                                   .and change(Race, :count).by(10)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end

        it '対象のhold,hold_daily,raceが更新されること' do
          hold_daily = Hold.find_by(pf_hold_id: 110).hold_dailies.find_by(hold_id_daily: 241)
          before_race_distances = Array.new(10, 500)
          after_race_distances = Array.new(9, 1020) << 1500

          expect { notifications_holding }
            .to change { Hold.find_by(pf_hold_id: 110).hold_name_jp }
            .from('間違った開催').to('川崎開催テスト２')
            .and change { HoldDaily.find(hold_daily.id).race_count }
            .from(4).to(9)
            .and change { hold_daily.races.order(:program_no).pluck(:race_distance) }
            .from(before_race_distances).to(after_race_distances)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end
      end

      context '引数のhold_idが複数あり取得できないhold_idが含まれる場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id },
              { 'key' => 'hold_id', 'value' => update_hold_id },
              { 'key' => 'hold_id', 'value' => empty_hold_id }
            ]
          }
        end

        before do
          PlatformSync.hold_update!(hold_id: update_hold_id)
          hold = Hold.find_by(pf_hold_id: 110)
          hold.update(hold_name_jp: '間違った開催')
          hold_daily = hold.hold_dailies.find_by(hold_id_daily: 241)
          hold_daily.update(race_count: 4)
          hold_daily.races.each { |race| race.update(race_distance: 500) }
        end

        it 'hold,hold_daily,raceが作成されず、result_code 600が返ること' do
          expect { notifications_holding }
            .to change(Hold, :count).by(0)
                                    .and change(HoldDaily, :count).by(0)
                                                                  .and change(Race, :count).by(0)
          expect(Hold.find_by(pf_hold_id: hold_id)).to be_blank
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end

        it 'hold,hold_daily,raceが更新されずに、result_code 600が返ること' do
          hold_daily = Hold.find_by(pf_hold_id: 110).hold_dailies.find_by(hold_id_daily: 241)

          expect { notifications_holding }
            .to not_change { Hold.find_by(pf_hold_id: 110).hold_name_jp }
            .and not_change { HoldDaily.find(hold_daily.id).race_count }
            .and not_change { hold_daily.races.order(:program_no).pluck(:race_distance) }
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end
    end

    context 'type_idが2だった場合' do
      context 'hold_idがnilだった場合' do
        let(:notification_params) do
          {
            type_id: 2,
            id_list: [
              { 'key' => 'hold_id', 'value' => nil }
            ]
          }
        end

        it 'result_code 600が返ること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end

      context 'hold_idがはあるがリストが取得できなかった場合' do
        let(:notification_params) do
          {
            type_id: 2,
            id_list: [
              { 'key' => 'hold_id', 'value' => empty_hold_id }
            ]
          }
        end

        it 'result_code 600が返ること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end

      context 'pf_hold_idが引数のhold_idであるholdがある場合' do
        let(:notification_params) do
          {
            type_id: 1,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id }
            ]
          }
        end

        it 'hold,hold_daily,raceが更新されること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end
      end
    end

    context 'type_idが3の場合' do
      before do
        create(:race, hold_daily_schedule: hold_daily_schedule, program_no: 1)
      end

      let(:notification_params) do
        {
          type_id: 3,
          id_list: [
            { 'key' => 'hold_id', 'value' => hold.pf_hold_id },
            { 'key' => 'hold_id_daily', 'value' => hold_daily.hold_id_daily }
          ]
        }
      end

      it 'race_detailが作成されること、result_code 100が返ること' do
        expect { notifications_holding }
          .to change(RaceDetail, :count).by(1)
        json = JSON.parse(response.body)
        expect(json).to eq({ 'result_code' => 100 })
      end

      context 'hold_id_dailyがnilの場合' do
        let(:notification_params) do
          {
            type_id: 3,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold.pf_hold_id },
              { 'key' => 'hold_id_daily', 'value' => nil }
            ]
          }
        end

        it 'race_detailが作成されないこと、result_code 600が返ること' do
          expect { notifications_holding }
            .to change(RaceDetail, :count).by(0)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end
    end

    context 'type_idが4の場合' do
      let(:race) { create(:race, hold_daily_schedule: hold_daily_schedule, program_no: 1, entries_id: '2021010222001') }
      let(:race_detail) { create(:race_detail, race: race, bike_count: 10, entries_id: '2021010222001') }

      let(:notification_params) do
        {
          type_id: 4,
          id_list: [
            { 'key' => 'entries_id', 'value' => '2021010222001' }
          ]
        }
      end

      it '対象のrace_detailが更新されること、result_code 100が返ること' do
        expect { notifications_holding }
          .to change { RaceDetail.find(race_detail.id).bike_count }.from('10').to('6')
        json = JSON.parse(response.body)
        expect(json).to eq({ 'result_code' => 100 })
      end

      context 'entries_idがnilの場合' do
        let(:notification_params) do
          {
            type_id: 3,
            id_list: [
              { 'key' => 'entries_id', 'value' => nil }
            ]
          }
        end

        it 'race_detailが更新されないこと、result_code 600が返ること' do
          expect { notifications_holding }
            .not_to change { RaceDetail.find(race_detail.id).bike_count }
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end
    end

    context 'type_idが5の場合' do
      let(:race) { create(:race, hold_daily_schedule: hold_daily_schedule, program_no: 1) }
      let(:race_detail) { create(:race_detail, entries_id: '2021030175002', race_status: '0') }

      let(:notification_params) do
        {
          type_id: 5,
          id_list: [
            { 'key' => 'entries_id', 'value' => '2021030175002' }
          ]
        }
      end

      it '対象のrace_detailに紐づくrace_resultが作成されること、race_detailが更新されること、result_code 100が返ること' do
        expect { notifications_holding }
          .to change { RaceDetail.find(race_detail.id).race_result.present? }.from(false).to(true).and \
            change { RaceDetail.find(race_detail.id).race_status }.from('0').to('15')
        json = JSON.parse(response.body)
        expect(json).to eq({ 'result_code' => 100 })
      end

      context 'entries_idがnilの場合' do
        let(:notification_params) do
          {
            type_id: 5,
            id_list: [
              { 'key' => 'entries_id', 'value' => nil }
            ]
          }
        end

        it 'race_detailが更新されないこと、result_code 600が返ること' do
          expect { notifications_holding }
            .not_to change { RaceDetail.find(race_detail.id).bike_count }
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end
    end

    context 'type_idが6,7,8,9だった場合(全て共通処理)' do
      context 'hold_idがnilだった場合' do
        let(:notification_params) do
          {
            type_id: 6,
            id_list: [
              { 'key' => 'hold_id', 'value' => nil }
            ]
          }
        end

        it 'result_code 600が返ること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end

      context 'hold_idがはあるがリストが取得できなかった場合' do
        let(:notification_params) do
          {
            type_id: 6,
            id_list: [
              { 'key' => 'hold_id', 'value' => empty_hold_id }
            ]
          }
        end

        it 'result_code 600が返ること' do
          notifications_holding
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end

      context 'pf_hold_idがparamsのhold_idであるholdがない場合' do
        let(:notification_params) do
          {
            type_id: 6,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id }
            ]
          }
        end

        it 'hold,hold_daily,raceが作成され、result_code 100が返ること' do
          expect { notifications_holding }
            .to change { Hold.find_by(pf_hold_id: hold_id).present? }
            .from(false).to(true)
            .and change(Hold, :count).by(1)
                                     .and change(HoldDaily, :count).by(2)
                                                                   .and change(Race, :count).by(10)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end
      end

      context 'pf_hold_idが引数のhold_idであるholdがある場合' do
        let(:notification_params) do
          {
            type_id: 6,
            id_list: [
              { 'key' => 'hold_id', 'value' => hold_id }
            ]
          }
        end

        before do # 事前に作成して、値を変更してupdateをかけて元に戻るかの検証
          PlatformSync.hold_update!(hold_id: hold_id)
          hold = Hold.find_by(pf_hold_id: 10)
          hold.update(hold_name_jp: '間違った開催')
          hold_daily = hold.hold_dailies.find_by(hold_id_daily: 241)
          hold_daily.update(race_count: 4)
          hold_daily.races.each { |race| race.update(race_distance: 500) }
        end

        it 'hold,hold_daily,raceが更新されること' do
          hold_daily = Hold.find_by(pf_hold_id: 10).hold_dailies.find_by(hold_id_daily: 241)
          before_race_distances = Array.new(10, 500)
          after_race_distances = Array.new(9, 1020) << 1500

          expect { notifications_holding }
            .to change { Hold.find_by(pf_hold_id: 10).hold_name_jp }
            .from('間違った開催').to('川崎開催テスト２')
            .and change { HoldDaily.find(hold_daily.id).race_count }
            .from(4).to(9)
            .and change { hold_daily.races.order(:program_no).pluck(:race_distance) }
            .from(before_race_distances).to(after_race_distances)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 100 })
        end
      end
    end

    context 'type_idが10の場合' do
      let(:hold) { create(:hold, pf_hold_id: 100) }
      let(:notification_params) do
        {
          type_id: 10,
          id_list: [
            { 'key' => 'hold_id', 'value' => pf_hold_id }
          ]
        }
      end
      let(:pf_hold_id) { hold.pf_hold_id }

      it 'time_trial_resultが登録されること、result_code 100が返ること' do
        expect { notifications_holding }
          .to change(TimeTrialResult, :count).from(0).to(1)
        json = JSON.parse(response.body)
        expect(json).to eq({ 'result_code' => 100 })
      end

      context 'hold_idがnilの場合' do
        let(:pf_hold_id) { nil }

        it 'race_detailが更新されないこと、result_code 600が返ること' do
          expect { notifications_holding }
            .not_to change(TimeTrialResult, :count)
          json = JSON.parse(response.body)
          expect(json).to eq({ 'result_code' => 600 })
        end
      end
    end

    context 'type_idが11の場合' do
      let(:notification_params) do
        {
          type_id: 11,
          id_list: [
            { 'key' => 'hold_id', 'value' => hold_id }
          ]
        }
      end

      it '通知を受けた前日の日付でplayer_updateが実行されて選手が登録されていること' do
        travel_to Date.new(2022, 1, 13) do
          expect { notifications_holding }.to change(Player, :count).from(0).to(2) \
                                                                    .and change { Player.all.pluck(:pf_player_id) }.from([]).to(%w[296 297]) # ['296', '297']は、lib/platform/mock_responses/update_players_20220112.jsonのplayer_id
        end
      end

      it 'result_code 100が返ること' do
        notifications_holding
        json = JSON.parse(response.body)
        expect(json).to eq({ 'result_code' => 100 })
      end
    end
  end
end
