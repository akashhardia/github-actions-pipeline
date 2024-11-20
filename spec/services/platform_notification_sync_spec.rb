# frozen_string_literal: true

require 'rails_helper'

describe 'platform_notification_sync' do # rubocop:disable RSpec/DescribeClass
  describe 'class.odds_creator!(odds_params)' do
    let(:entries_id) { create(:race_detail).entries_id }
    let(:odds_params) do
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

    context '正しいパラメータを渡す場合' do
      it 'odds関連モデルが保存される' do
        expect { PlatformNotificationSync.odds_creator!(odds_params) }.to change(OddsInfo, :count).by(1).and change(OddsList, :count).by(2).and change(OddsDetail, :count).by(3)
      end
    end

    context '存在しないentries_idを渡す' do
      let(:entries_id) { 999 }

      it 'NotFoundエラーが返る' do
        expect { PlatformNotificationSync.odds_creator!(odds_params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'class.close_time_update!(vote_params)' do
    let(:race_detail) { create(:race_detail) }
    let(:entries_id) { race_detail.entries_id }
    let(:pf_hold_id) { race_detail.pf_hold_id }
    let(:hold_id_daily) { race_detail.hold_id_daily }
    let(:close_time) { '2021-02-25 17:00:00 +0900' }
    let(:vote_params) do
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

    context '正しいパラメータを渡す場合' do
      it 'race_detailsのclose_timeが保存される' do
        expect { PlatformNotificationSync.close_time_update!(vote_params) }.to change { RaceDetail.find(race_detail.id).close_time.to_s }.from('').to(close_time)
      end
    end

    context '存在しないentries_idを渡す' do
      let(:entries_id) { 999 }

      it 'NotFoundエラーが返る' do
        expect { PlatformNotificationSync.close_time_update!(vote_params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context '存在しないhold_idを渡す' do
      let(:pf_hold_id) { 999 }

      it 'NotFoundエラーが返る' do
        expect { PlatformNotificationSync.close_time_update!(vote_params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context '存在しないhold_id_dailyを渡す' do
      let(:hold_id_daily) { 999 }

      it 'NotFoundエラーが返る' do
        expect { PlatformNotificationSync.close_time_update!(vote_params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'class.payoff_creator!(payoff_params)' do
    subject(:payoff_create) { post v1_notifications_payoff_url, params: params, headers: access_token }

    let(:entries_id) { create(:race_detail).entries_id }
    let(:payoff_params) do
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

    context '正しいパラメータを渡す場合' do
      it 'payoff関連のモデルが保存される' do
        expect { PlatformNotificationSync.payoff_creator!(payoff_params) }.to change(PayoffList, :count).by(2).and change(Rank, :count).by(4)
      end

      it 'rank正しく保存される' do
        PlatformNotificationSync.payoff_creator!(payoff_params)
        expect(Rank.where(arrival_order: 1).pluck(:car_number).sort).to eq([3, 4])
        expect(Rank.where(arrival_order: 3).pluck(:car_number)).to eq([2])
        expect(Rank.where(arrival_order: 4).pluck(:car_number)).to eq([1])
      end
    end

    context 'entries_idに該当するrace_detailがない場合' do
      let(:entries_id) { 9999 }

      it 'NotFoundエラーが返る' do
        expect { PlatformNotificationSync.payoff_creator!(payoff_params) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
