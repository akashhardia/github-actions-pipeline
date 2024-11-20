# frozen_string_literal: true

require 'rails_helper'
require 'rake_helper'

describe 'pf_250_api raketask' do # rubocop:disable RSpec/DescribeClass
  let(:env_hold_id) { 10 }
  let(:env_year) { 2020 }
  let(:env_month) { 10 }
  let(:env_update) { 20_200_930 }
  let(:env_player_id_1) { 1 }
  let(:env_player_id_2) { 2 }
  let(:env_update_date_valid) { '20200101' }
  let(:env_update_date_invalid) { '1234567' }
  let(:hold) { create(:hold, pf_hold_id: '1') }
  let(:holds_get_task) { Rake.application['pf_250_api:holds_get'] }
  let(:get_players_update_task) { Rake.application['pf_250_api:get_players_update'] }
  let(:race_details_get_task) { Rake.application['pf_250_api:race_details_get'] }
  let(:holding_word_codes_update_task) { Rake.application['pf_250_api:holding_word_codes_update'] }
  let(:hold_daily) { create(:hold_daily, hold: hold) }
  let(:race) { create(:race, program_no: 1, hold_daily_schedule: create(:hold_daily_schedule, hold_daily: hold_daily)) }
  let(:annual_schedule_update_task) { Rake.application['pf_250_api:annual_schedule_update'] }
  let(:player_result_update_task) { Rake.application['pf_250_api:player_result_update'] }

  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  describe 'pf_250_api:get_players_update' do
    let(:task) { 'pf_250_api:get_players_update' }

    before do
      player = Player.create(pf_player_id: '2',
                             regist_num: 1111,
                             player_class: 2222)
      player.create_player_original_info(pf_250_regist_id: '2110100002')
    end

    context '環境変数を渡さずに実行した場合' do
      it 'playerモデルが保存されない' do
        expect { get_players_update_task.invoke }.not_to change(Player, :count)
      end
    end

    context '環境変数UPDATEを渡して実行した場合' do
      it 'レコードのない選手(pf_250_regist_id: "2107070001")はplayerレコードを新規追加し、レコードが既存の選手(pf_250_regist_id: "2110100002")は更新する' do
        allow(ENV).to receive(:[]).with('UPDATE').and_return(env_update)
        expect { get_players_update_task.invoke }.to change { Player.find_by(pf_player_id: '1').present? }.from(false).to(true).and \
          change { Player.find_by(pf_player_id: '2').updated_at }.and \
            change(Player, :count).from(1).to(2)
      end
    end

    context 'レコードのない選手の環境変数PLAYER_IDを渡して実行した場合' do
      it 'playerレコードを新規追加する' do
        allow(ENV).to receive(:[]).with('PLAYER_ID').and_return(env_player_id_1)
        expect { get_players_update_task.invoke }.to change { Player.find_by(pf_player_id: '1').present? }.from(false).to(true).and \
          change(Player, :count).from(1).to(2)
      end
    end

    context 'レコードのある選手の環境変数PLAYER_IDを渡して実行した場合' do
      it 'playerレコードを更新し、かつレコードは追加しない' do
        allow(ENV).to receive(:[]).with('PLAYER_ID').and_return(env_player_id_2)
        expect { get_players_update_task.invoke }.to change { Player.find_by(pf_player_id: '2').updated_at }.and \
          change(Player, :count).by(0)
      end
    end
  end

  describe 'pf_250_api:race_details_get' do
    context '環境変数を渡さずに実行した場合' do
      it 'RaceDetailモデルが保存されない' do
        expect { race_details_get_task.invoke }.to raise_error(PfApiError)
        expect(RaceDetail.count).to eq(0)
      end
    end

    context '環境変数YYYY_MMを渡す' do
      it '指定した年と月のholdモデルに関連するrace_detailが保存される' do
        race
        allow(ENV).to receive(:[]).with('YYYY_MM').and_return(hold.first_day.strftime('%Y_%m'))
        expect { race_details_get_task.invoke }.to change(RaceDetail, :count).by(1).and \
          change(VoteInfo, :count).by(2).and \
            change(RacePlayer, :count).by(1).and \
              change(BikeInfo, :count).by(1).and \
                change(FrontWheelInfo, :count).by(1).and \
                  change(RearWheelInfo, :count).by(1)
      end
    end
  end

  describe 'pf_250_api:holding_word_codes_update' do
    context '環境変数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { holding_word_codes_update_task.invoke }.to raise_error(PfApiError)
      end
    end

    context '引数を正しく入力して実行した場合' do
      it 'WordCodeとWordCodeが登録されること' do
        allow(ENV).to receive(:[]).with('UPDATE').and_return(env_update_date_valid)
        expect { holding_word_codes_update_task.invoke }.to change(WordCode, :count).and \
          change(WordName, :count)
      end
    end

    context '引数が不正の場合' do
      it 'Errorが上がる' do
        allow(ENV).to receive(:[]).with('UPDATE').and_return(env_update_date_invalid)
        expect { holding_word_codes_update_task.invoke }.to raise_error(PfApiError)
      end
    end
  end

  describe 'pf_250_api:annual_schedule_update' do
    context '環境変数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { annual_schedule_update_task.invoke }.to raise_error(PfApiError)
      end
    end

    context '引数を正しく入力して実行した場合' do
      it 'AnnualScheduleが登録されること' do
        allow(ENV).to receive(:[]).with('PROMOTER').and_return('0340')
        allow(ENV).to receive(:[]).with('PROMOTER_YEAR').and_return('2021')
        expect { annual_schedule_update_task.invoke }.to change(AnnualSchedule, :count).by(2)
      end
    end
  end

  describe 'pf_250_api:player_result_update' do
    let(:task) { 'pf_250_api:player_result_update' }

    let(:firstday_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today) }
    let(:player_1) { create(:player, pf_player_id: '1', name_jp: 'イチ') }
    let(:hold_player_1) { create(:hold_player, hold: firstday_hold, player: player_1) }
    let(:player_result_1) { create(:player_result, player_id: player_1.id) }

    let(:player_miss_day) { create(:player, pf_player_id: '6', name_jp: '欠場') }
    let(:hold_player_miss_day) { create(:hold_player, hold: firstday_hold, player: player_miss_day) }
    let(:player_result_miss_day) { create(:player_result, player_id: player_miss_day.id) }

    let(:yesterday_firstday_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today - 1) }
    let(:player_2) { create(:player, pf_player_id: '2', name_jp: 'ニ') }
    let(:hold_player_2) { create(:hold_player, hold: yesterday_firstday_hold, player: player_2) }
    let(:player_result_2) { create(:player_result, player_id: player_2.id) }

    let(:twodaysago_firstday_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today - 2) }
    let(:player_3) { create(:player, pf_player_id: '3', name_jp: 'サン') }
    let(:hold_player_3) { create(:hold_player, hold: twodaysago_firstday_hold, player: player_3) }
    let(:player_result_3) { create(:player_result, player_id: player_3.id) }

    let(:threedaysago_firstday_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today - 3) }
    let(:player_4) { create(:player, pf_player_id: '4', name_jp: 'ヨン') }
    let(:hold_player_4) { create(:hold_player, hold: threedaysago_firstday_hold, player: player_4) }
    let(:player_result_4) { create(:player_result, player_id: player_4.id) }

    let(:fourdaysago_firstday_hold) { create(:hold, promoter_year: 2021, period: 'spring', round: 1, first_day: Time.zone.today - 4) }
    let(:player_5) { create(:player, pf_player_id: '5', name_jp: 'ゴ') }
    let(:hold_player_5) { create(:hold_player, hold: fourdaysago_firstday_hold, player: player_5) }
    let(:player_result_5) { create(:player_result, player_id: player_5.id) }

    before do
      create(:mediated_player, hold_player: hold_player_1, pf_player_id: player_1.pf_player_id)
      create(:mediated_player, hold_player: hold_player_2, pf_player_id: player_2.pf_player_id)
      create(:mediated_player, hold_player: hold_player_3, pf_player_id: player_3.pf_player_id)
      create(:mediated_player, hold_player: hold_player_4, pf_player_id: player_4.pf_player_id)
      create(:mediated_player, hold_player: hold_player_5, pf_player_id: player_5.pf_player_id)
      create(:mediated_player, hold_player: hold_player_miss_day, pf_player_id: player_miss_day.pf_player_id, miss_day: '20210910')
    end

    context '引数なしで実行した場合' do
      it '本日日付から3日以内の開催に紐づく欠場以外の選手の戦績が更新されること' do
        expect { player_result_update_task.invoke }.to change { player_result_1.reload.updated_at }.and \
          change { player_result_2.reload.updated_at }.and \
            change { player_result_3.reload.updated_at }.and \
              change { player_result_4.reload.updated_at }.and \
                change(player_1.player_race_results, :count).from(0).to(3).and \
                  not_change(player_2.player_race_results, :count).and \
                    change(player_3.player_race_results, :count).from(0).to(2).and \
                      change(player_4.player_race_results, :count).from(0).to(2)
      end

      it '本日日付から4日前の開催に紐づく選手の戦績が更新されないこと' do
        expect { player_result_update_task.invoke }.to not_change { player_result_5.reload.updated_at }.and \
          not_change(player_5.player_race_results, :count)
      end
    end

    context '引数ありで実行した場合（文字列）' do
      let(:env_update) { Time.zone.today.strftime('%Y%m%d') }

      it '引数の日付から3日以内の開催に紐づく選手の戦績が更新されること' do
        allow(ENV).to receive(:[]).with('UPDATE').and_return(env_update)
        expect { player_result_update_task.invoke }.to change { player_result_1.reload.updated_at }.and \
          change { player_result_2.reload.updated_at }.and \
            change { player_result_3.reload.updated_at }.and \
              change { player_result_4.reload.updated_at }.and \
                change(player_1.player_race_results, :count).from(0).to(3).and \
                  not_change(player_2.player_race_results, :count).and \
                    change(player_3.player_race_results, :count).from(0).to(2).and \
                      change(player_4.player_race_results, :count).from(0).to(2)
      end

      it '引数の日付から4日前の開催に紐づく選手の戦績が更新されないこと' do
        expect { player_result_update_task.invoke }.to not_change { player_result_5.reload.updated_at }.and \
          not_change(player_5.player_race_results, :count)
      end
    end

    context '引数ありで実行した場合（date）' do
      let(:env_update) { Time.zone.today }

      it '引数の日付から3日以内の開催に紐づく選手の戦績が更新されること' do
        allow(ENV).to receive(:[]).with('UPDATE').and_return(env_update)
        expect { player_result_update_task.invoke }.to change { player_result_1.reload.updated_at }.and \
          change { player_result_2.reload.updated_at }.and \
            change { player_result_3.reload.updated_at }.and \
              change { player_result_4.reload.updated_at }.and \
                change(player_1.player_race_results, :count).from(0).to(3).and \
                  not_change(player_2.player_race_results, :count).and \
                    change(player_3.player_race_results, :count).from(0).to(2).and \
                      change(player_4.player_race_results, :count).from(0).to(2)
      end

      it '引数の日付から4日前の開催に紐づく選手の戦績が更新されないこと' do
        expect { player_result_update_task.invoke }.to not_change { player_result_5.reload.updated_at }.and \
          not_change(player_5.player_race_results, :count)
      end
    end

    context '更新対象のデータがない場合' do
      it '正常に終了すること' do
        PlayerResult.delete_all
        allow(ENV).to receive(:[]).with('UPDATE').and_return(env_update)
        expect { player_result_update_task.invoke }.to not_change(PlayerResult, :count).and \
          not_change(PlayerRaceResult, :count)
      end
    end
  end
end
