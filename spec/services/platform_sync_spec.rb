# frozen_string_literal: true

require 'rails_helper'

describe 'platform_sync' do # rubocop:disable RSpec/DescribeClass
  let(:hold_id) { 10 }
  let(:empty_hold_id) { 100 }
  let(:year_params) { 2020 }
  let(:month_params) { 10 }
  let(:update_params) { 20_200_930 }
  let(:player_id_1) { 1 }
  let(:player_id_2) { 2 }
  let(:hold) { create(:hold, pf_hold_id: '1') }
  let(:hold_daily) { create(:hold_daily, hold: hold) }

  describe 'class.hold_update!(hold_id)' do
    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.hold_update! }.to raise_error(PfApiError, '[年 & 月] または [開催ID] を入力してください。')
      end
    end

    context 'yearのみ渡す' do
      it 'PfApiErrorが上がる' do
        expect { PlatformSync.hold_update!(year: year_params) }.to raise_error(PfApiError, '[年]と[月]はセットで入力してください。')
      end
    end

    context 'monthのみ渡す' do
      it 'PfApiErrorが上がる' do
        expect { PlatformSync.hold_update!(month: month_params) }.to raise_error(PfApiError, '[年]と[月]はセットで入力してください。')
      end
    end

    context 'year,month,hold_id全て渡す場合' do
      it 'PfApiErrorが上がる' do
        expect { PlatformSync.hold_update!(year: year_params, month: month_params, hold_id: hold_id) }.to raise_error(PfApiError, '[年 & 月] または [開催ID] のどちらか一方を入力してください。')
      end
    end

    context 'リストが返ってこないhold_idを渡した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.hold_update!(hold_id: empty_hold_id) }.to raise_error(PfApiError, 'hold_listが取得できませんでした。')
      end
    end

    context 'pf_hold_idが引数のhold_idであるholdがない場合' do
      it 'hold,hold_daily,raceが作成されること' do
        expect { PlatformSync.hold_update!(hold_id: hold_id) }.to change { Hold.find_by(pf_hold_id: hold_id).present? }.from(false).to(true).and \
          change(Hold, :count).by(1).and \
            change(HoldDaily, :count).by(2).and \
              change(Race, :count).by(10)
      end
    end

    context 'pf_hold_idが引数のhold_idであるholdがある場合' do
      before do # 事前に作成して、値を変更してupdateをかけて元に戻るかの検証
        template_seat_sale = create(:template_seat_sale)
        template_seat_area = create(:template_seat_area, template_seat_sale: template_seat_sale)
        template_seat_type = create(:template_seat_type, template_seat_sale: template_seat_sale)
        create(:master_seat, master_seat_area: template_seat_area.master_seat_area, master_seat_type: template_seat_type.master_seat_type)
        create(:template_seat, template_seat_area: template_seat_area, template_seat_type: template_seat_type)

        # 自動生成値モデルの作成
        4.times { |n| create(:template_seat_sale_schedule, template_seat_sale: template_seat_sale, target_hold_schedule: n) }

        PlatformSync.hold_update!(year: nil, month: nil, hold_id: hold_id)
        hold.update(hold_name_jp: '間違った開催')
        hold.update(season: '間違ったシーズン')
        hold_daily.update(race_count: 4)
        hold_daily.races.each { |race| race.update(race_distance: 500, pattern_code: '4', time_zone_code: 2) }
      end

      let(:hold) { Hold.find_by(pf_hold_id: hold_id) }
      let(:hold_daily) { hold.hold_dailies.find_by(hold_id_daily: 241) }

      it 'hold,hold_daily,raceが更新されること' do
        before_race_distances = Array.new(10, 500)
        after_race_distances = Array.new(9, 1020) << 1500

        before_race_pattern_code = Array.new(10, '4')
        after_race_pattern_code = Array.new(9, '6') << '0'

        before_race_time_zone_code = Array.new(10, 2)
        after_race_time_zone_code = Array.new(10, 1)

        expect { PlatformSync.hold_update!(hold_id: hold_id) }
          .to change { Hold.find_by(pf_hold_id: 10).hold_name_jp }
          .from('間違った開催').to('川崎開催テスト２')
          .and change { Hold.find_by(pf_hold_id: 10).season }
          .from('間違ったシーズン').to('決定戦')
          .and change { HoldDaily.find(hold_daily.id).race_count }
          .from(4).to(9)
          .and change { HoldDaily.find(hold_daily.id).races.order(:program_no).pluck(:race_distance) }
          .from(before_race_distances).to(after_race_distances)
          .and change { HoldDaily.find(hold_daily.id).races.order(:program_no).pluck(:pattern_code) }
          .from(before_race_pattern_code).to(after_race_pattern_code)
          .and change { HoldDaily.find(hold_daily.id).races.order(:program_no).pluck(:time_zone_code) }
          .from(before_race_time_zone_code).to(after_race_time_zone_code)
      end

      context '販売情報が存在しない場合' do
        before do
          hold_daily.hold_daily_schedules.map { |h| h.seat_sales.destroy_all }
        end

        context 'racesが存在する場合' do
          it '販売情報を新たに作成する' do
            expect { PlatformSync.hold_update!(hold_id: hold_id) }.to change { hold_daily.reload.seat_sales.count }.from(0).to(2)
          end
        end

        context 'racesが存在しない場合' do
          before do
            hold_daily.hold_daily_schedules.map { |h| h.races.destroy_all }
          end

          it '販売情報を新たに作成する' do
            expect { PlatformSync.hold_update!(hold_id: hold_id) }.to change { hold_daily.reload.seat_sales.count }.from(0).to(2)
          end
        end
      end

      context '既に販売情報が存在する場合' do
        it '販売情報を新規作成も更新もしない' do
          expect { PlatformSync.hold_update!(hold_id: hold_id) }.not_to change { hold_daily.reload.seat_sales.count }.from(2)
          expect { PlatformSync.hold_update!(hold_id: hold_id) }.not_to change { hold_daily.seat_sales.reload.map(&:updated_at) }
        end
      end
    end

    context '指定したhold_idのholdが既に存在し、hold_dailiesが存在しない場合' do
      before do
        create(:hold, pf_hold_id: hold_id, hold_name_jp: '元の開催名')
      end

      let(:target_hold) { Hold.find_by(pf_hold_id: hold_id) }

      it 'hold以下のアソシエーション（hold_dailies, hold_daily_schedules, races）が登録されること' do
        expect { PlatformSync.hold_update!(hold_id: hold_id) }.to change(target_hold.hold_dailies.reload, :count).from(0).to(2).and \
          change(target_hold.hold_daily_schedules.reload, :count).from(0).to(2).and \
            change(target_hold.races.reload, :count).from(0).to(10)
      end

      it 'holdがPFの値に更新されること' do
        expect { PlatformSync.hold_update!(hold_id: hold_id) }.to change { target_hold.reload.hold_name_jp }.from('元の開催名').to('川崎開催テスト２')
      end
    end

    context 'hold_dailyに出走表確定済みレースと未確定レースが両方存在する場合' do
      before do
        PlatformSync.hold_update!(hold_id: hold_id)
        # program_no 1～5にのみ出走表（race_detail, race_players）を紐付ける
        hold_daily = Hold.find_by(pf_hold_id: hold_id).hold_dailies.last
        races_with_race_detail = hold_daily.races.where(program_no: 1..5)
        races_with_race_detail.each do |race|
          create(:race_detail, race: race, entries_id: race.entries_id, post_time: race.post_time)
        end
      end

      context '出走表未確定の最初のレースがカットされた場合' do
        let(:mock_hold_id) { '10_race_without_detail_cut' }

        it '出走表未確定のレース数が1つ減ること' do
          expect { PlatformSync.hold_update!(hold_id: mock_hold_id) }.to \
            change(Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where(race_detail: { id: nil }), :count).by(-1)
        end

        it '出走表確定済みレースはraceレコードにrace_detailが紐付けされ、PFのレスポンスの値と一致していること' do
          response = PlatformSync.hold_update!(hold_id: mock_hold_id)

          races_with_race_detail = Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where.not(race_detail: { id: nil })
          races_with_race_detail.each_with_index do |race, i|
            expect(race.race_detail.entries_id).to eq(response[0]['days_list'][1]['race_list'][i]['entries_id'])
          end
        end

        it '出走表確定済みレースはraceとrace_detailとで出走ID（entries_id）が一致すること' do
          PlatformSync.hold_update!(hold_id: mock_hold_id)

          races_with_race_detail = Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where.not(race_detail: { id: nil })
          races_with_race_detail.each do |race|
            expect(race.entries_id).to eq(race.race_detail.entries_id)
          end
        end

        it '出走表確定済みレースはraceとrace_detailとで発走予定時刻（post_time）が一致すること' do
          PlatformSync.hold_update!(hold_id: mock_hold_id)

          races_with_race_detail = Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where.not(race_detail: { id: nil })
          races_with_race_detail.each do |race|
            expect(race.post_time).to eq(race.race_detail.post_time)
          end
        end
      end

      context '出走表確定済みの最初の1レースがカットされた場合' do
        let(:mock_hold_id) { '10_race_with_detail_cut' }

        it '出走表確定済みのレース数が1つ減ること' do
          expect { PlatformSync.hold_update!(hold_id: mock_hold_id) }.to \
            change(Hold.find_by(pf_hold_id: hold_id).races, :count).by(-1)
        end
      end

      context '午後の全レースがカットされた場合' do
        let(:mock_hold_id) { '10_all_pm_races_cut' }

        it 'hold_daily_scheduleが午前中の1つのみになること' do
          expect { PlatformSync.hold_update!(hold_id: mock_hold_id) }.to \
            change { Hold.find_by(pf_hold_id: hold_id).hold_daily_schedules.pluck(:daily_no) }.from(%w[am pm]).to(['am'])
        end
      end
    end

    context 'yearとmonthを渡す' do
      it '指定した年と月のholdモデルが保存される' do
        expect { PlatformSync.hold_update!(year: year_params, month: month_params) }.to change(Hold, :count).by(2).and \
          change(HoldDaily, :count).by(4).and \
            change(Race, :count).by(6)
      end
    end
  end

  describe 'class.hold_bulk_update!(hold_id_list)' do
    context '引数に空配列を渡して実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.hold_bulk_update!([]) }.to raise_error(PfApiError, ' [開催IDリスト] を入力してください。')
      end
    end

    context 'リストが返ってこないhold_idを渡した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.hold_bulk_update!([empty_hold_id]) }.to raise_error(PfApiError, 'hold_listが取得できませんでした。')
      end
    end

    context 'リストが返ってこないhold_idと正常に処理できるhold_idを渡した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.hold_bulk_update!([hold_id, empty_hold_id]) }.to raise_error(PfApiError, 'hold_listが取得できませんでした。')
      end
    end

    context 'pf_hold_idが引数のhold_idであるholdがない場合' do
      it 'hold,hold_daily,raceが作成されること' do
        expect { PlatformSync.hold_bulk_update!([hold_id]) }.to change { Hold.find_by(pf_hold_id: hold_id).present? }.from(false).to(true).and \
          change(Hold, :count).by(1).and \
            change(HoldDaily, :count).by(2).and \
              change(Race, :count).by(10)
      end
    end

    context 'pf_hold_idが引数のhold_idであるholdがある場合' do
      before do # 事前に作成して、値を変更してupdateをかけて元に戻るかの検証
        template_seat_sale = create(:template_seat_sale)
        template_seat_area = create(:template_seat_area, template_seat_sale: template_seat_sale)
        template_seat_type = create(:template_seat_type, template_seat_sale: template_seat_sale)
        create(:master_seat, master_seat_area: template_seat_area.master_seat_area, master_seat_type: template_seat_type.master_seat_type)
        create(:template_seat, template_seat_area: template_seat_area, template_seat_type: template_seat_type)

        # 自動生成値モデルの作成
        4.times { |n| create(:template_seat_sale_schedule, template_seat_sale: template_seat_sale, target_hold_schedule: n) }

        PlatformSync.hold_bulk_update!([hold_id])
        hold.update(hold_name_jp: '間違った開催')
        hold.update(season: '間違ったシーズン')
        hold_daily.update(race_count: 4)
        hold_daily.races.each { |race| race.update(race_distance: 500) }
      end

      let(:hold) { Hold.find_by(pf_hold_id: hold_id) }
      let(:hold_daily) { hold.hold_dailies.find_by(hold_id_daily: 241) }

      it 'hold,hold_daily,raceが更新されること' do
        before_race_distances = Array.new(10, 500)
        after_race_distances = Array.new(9, 1020) << 1500

        expect { PlatformSync.hold_bulk_update!([hold_id]) }
          .to change { Hold.find_by(pf_hold_id: 10).hold_name_jp }
          .from('間違った開催').to('川崎開催テスト２')
          .and change { Hold.find_by(pf_hold_id: 10).season }
          .from('間違ったシーズン').to('決定戦')
          .and change { HoldDaily.find(hold_daily.id).race_count }
          .from(4).to(9)
          .and change { HoldDaily.find(hold_daily.id).races.order(:program_no).pluck(:race_distance) }
          .from(before_race_distances).to(after_race_distances)
      end

      context '販売情報が存在しない場合' do
        before do
          hold_daily.hold_daily_schedules.map { |h| h.seat_sales.destroy_all }
        end

        context 'racesが存在する場合' do
          it '販売情報を新たに作成する' do
            expect { PlatformSync.hold_bulk_update!([hold_id]) }.to change { hold_daily.reload.seat_sales.count }.from(0).to(2)
          end
        end

        context 'racesが存在しない場合' do
          before do
            hold_daily.hold_daily_schedules.map { |h| h.races.destroy_all }
          end

          it '販売情報を新たに作成する' do
            expect { PlatformSync.hold_bulk_update!([hold_id]) }.to change { hold_daily.reload.seat_sales.count }.from(0).to(2)
          end
        end
      end

      context '既に販売情報が存在する場合' do
        it '販売情報を新規作成も更新もしない' do
          expect { PlatformSync.hold_bulk_update!([hold_id]) }.not_to change { hold_daily.reload.seat_sales.count }.from(2)
          expect { PlatformSync.hold_bulk_update!([hold_id]) }.not_to change { hold_daily.seat_sales.reload.map(&:updated_at) }
        end
      end
    end

    context '指定したhold_idのholdが既に存在し、hold_dailiesが存在しない場合' do
      before do
        create(:hold, pf_hold_id: hold_id, hold_name_jp: '元の開催名')
      end

      let(:target_hold) { Hold.find_by(pf_hold_id: hold_id) }

      it 'hold以下のアソシエーション（hold_dailies, hold_daily_schedules, races）が登録されること' do
        expect { PlatformSync.hold_bulk_update!([hold_id]) }.to change(target_hold.hold_dailies.reload, :count).from(0).to(2).and \
          change(target_hold.hold_daily_schedules.reload, :count).from(0).to(2).and \
            change(target_hold.races.reload, :count).from(0).to(10)
      end

      it 'holdがPFの値に更新されること' do
        expect { PlatformSync.hold_bulk_update!([hold_id]) }.to change { target_hold.reload.hold_name_jp }.from('元の開催名').to('川崎開催テスト２')
      end
    end

    context 'hold_dailyに出走表確定済みレースと未確定レースが両方存在する場合' do
      before do
        PlatformSync.hold_update!(hold_id: hold_id)
        # program_no 1～5にのみ出走表（race_detail, race_players）を紐付ける
        hold_daily = Hold.find_by(pf_hold_id: hold_id).hold_dailies.last
        races_with_race_detail = hold_daily.races.where(program_no: 1..5)
        races_with_race_detail.each do |race|
          create(:race_detail, race: race, entries_id: race.entries_id, post_time: race.post_time)
        end
      end

      context '出走表未確定の最初のレースがカットされた場合' do
        let(:mock_hold_id) { '10_race_without_detail_cut' }

        it '出走表未確定のレース数が1つ減ること' do
          expect { PlatformSync.hold_bulk_update!([mock_hold_id]) }.to \
            change(Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where(race_detail: { id: nil }), :count).by(-1)
        end

        it '出走表確定済みレースはraceとrace_detailとで出走ID（entries_id）が一致すること' do
          PlatformSync.hold_bulk_update!([mock_hold_id])

          races_with_race_detail = Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where.not(race_detail: { id: nil })
          races_with_race_detail.each do |race|
            expect(race.entries_id).to eq(race.race_detail.entries_id)
          end
        end

        it '出走表確定済みレースはraceとrace_detailとで発走予定時刻（post_time）が一致すること' do
          PlatformSync.hold_bulk_update!([mock_hold_id])

          races_with_race_detail = Hold.find_by(pf_hold_id: hold_id).races.includes(:race_detail).where.not(race_detail: { id: nil })
          races_with_race_detail.each do |race|
            expect(race.post_time).to eq(race.race_detail.post_time)
          end
        end
      end

      context '出走表確定済みの最初の1レースがカットされた場合' do
        let(:mock_hold_id) { '10_race_with_detail_cut' }

        it '出走表確定済みのレース数が1つ減ること' do
          expect { PlatformSync.hold_bulk_update!([mock_hold_id]) }.to \
            change(Hold.find_by(pf_hold_id: hold_id).races, :count).by(-1)
        end
      end

      context '午後の全レースがカットされた場合' do
        let(:mock_hold_id) { '10_all_pm_races_cut' }

        it 'hold_daily_scheduleが午前中の1つのみになること' do
          expect { PlatformSync.hold_bulk_update!([mock_hold_id]) }.to \
            change { Hold.find_by(pf_hold_id: hold_id).hold_daily_schedules.pluck(:daily_no) }.from(%w[am pm]).to(['am'])
        end
      end
    end
  end

  describe 'class.players_update(update_date, pf_player_id)' do
    context '引数をnilで実行した場合' do
      it 'playerモデルが保存されない' do
        allow(Rails.logger).to receive(:error).with('引数を確認してください。')
        expect { PlatformSync.player_update(nil, nil) }.not_to change(Player, :count)
        expect(Rails.logger).to have_received(:error).with('引数を確認してください。')
      end
    end

    context 'updateを渡して実行した場合、' do
      let!(:existing_player) do
        Player.create(pf_player_id: '1234',
                      regist_num: 1111,
                      player_class: 2222)
      end
      let!(:mock_response_player_list) do
        update_players_mock_response = ActiveSupport::JSON.decode(File.read('lib/platform/mock_responses/update_players.json')).to_json
        JSON.parse(update_players_mock_response)['id_list']
      end
      let!(:existing_player_response) { mock_response_player_list[0] }
      let!(:new_player_response) { mock_response_player_list[1] }
      let(:existing_pf_250_regist_id) { '2107070001' } # lib/platform/mock_responses/update_players.json のplayer_id: "1"の'250id'と一致

      before do
        PlayerOriginalInfo.create(player: existing_player,
                                  pf_250_regist_id: existing_pf_250_regist_id)
      end

      it 'レスポンスの250idと一致するpf_250_regist_idを持つplayer_original_infoレコードがある場合、レスポンスの選手情報とplayer, player_original_infoレコードが一致する' do
        PlatformSync.player_update(update_params, nil)

        updated_player_original_info = PlayerOriginalInfo.find_by(pf_250_regist_id: existing_pf_250_regist_id)
        updated_player = updated_player_original_info.player
        expect(updated_player.pf_player_id).to eq(existing_player_response['player_id'])
        expect(updated_player.regist_num).to eq(existing_player_response['regist_num'])
        expect(updated_player.player_class).to eq(existing_player_response['player_class'])
        expect(updated_player_original_info.pf_250_regist_id).to eq(existing_player_response['original_info']['250id'])
      end

      it 'レスポンスの250idと一致するpf_250_regist_idを持つplayer_original_infoレコードがない場合、playerレコードとplayer_original_infoレコードが新規追加される' do
        expect { PlatformSync.player_update(update_params, nil) }.to \
          change { Player.find_by(pf_player_id: new_player_response['player_id']).present? }.from(false).to(true).and \
            change { Player.find_by(pf_player_id: new_player_response['player_id'])&.pf_250_regist_id }.from(nil).to(new_player_response['original_info']['250id']).and \
              change(Player, :count).from(1).to(2).and \
                change(PlayerOriginalInfo, :count).from(1).to(2)
      end
    end

    context 'pf_player_idを指定した場合、' do
      let!(:existing_player) do
        Player.create(pf_player_id: '1',
                      regist_num: 1111,
                      player_class: 2222)
      end
      let!(:existing_pf_250_regist_id) { '2107070001' } # lib/platform/mock_responses/player_id_1_players.json のplayer_id: "1"の'250id'と一致
      let!(:existing_player_original_info) do
        PlayerOriginalInfo.create(player: existing_player,
                                  pf_250_regist_id: existing_pf_250_regist_id)
      end

      let!(:mock_response_existing_player) do
        update_players_mock_response = ActiveSupport::JSON.decode(File.read('lib/platform/mock_responses/player_id_1_players.json')).to_json
        JSON.parse(update_players_mock_response)['id_list'][0]
      end
      let!(:mock_response_new_player) do
        update_players_mock_response = ActiveSupport::JSON.decode(File.read('lib/platform/mock_responses/player_id_2_players.json')).to_json
        JSON.parse(update_players_mock_response)['id_list'][0]
      end

      it 'portalとプラットフォームの両方にデータがある選手の場合、playerレコードとplayer_original_infoレコードを更新し、かつレコードは追加しない' do
        expect { PlatformSync.player_update(nil, existing_player.pf_player_id) }.to \
          change(Player, :count).by(0).and \
            change(PlayerOriginalInfo, :count).by(0).and \
              change { Player.find(existing_player.id).regist_num }.from(existing_player.regist_num).to(mock_response_existing_player['regist_num']).and \
                change { PlayerOriginalInfo.find(existing_player_original_info.id).last_name_jp }.from(existing_player_original_info['last_name_jp'])
                                                                                                 .to(mock_response_existing_player['original_info']['last_name_jp'])
      end

      it 'portalにレコードがなく、プラットフォームにデータがある選手の場合、playerレコードとplayer_original_infoレコードが追加される' do
        expect { PlatformSync.player_update(nil, mock_response_new_player['player_id']) }.to \
          change(Player, :count).by(1).and \
            change(PlayerOriginalInfo, :count).by(1)
      end

      it 'プラットフォームにデータがない選手の場合、エラーが返る' do
        expect { PlatformSync.player_update(nil, 99999) }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end
  end

  describe 'class.player_update_by_250id(pf_250id)' do
    subject(:player_update_by_250id) { PlatformSync.player_update_by_250id(pf_250id) }

    context '引数をnilで実行した場合' do
      let(:pf_250id) { nil }

      it 'playerモデルが保存されない' do
        allow(Rails.logger).to receive(:error).with('引数を指定してください。')
        expect { player_update_by_250id }.not_to change(Player, :count)
        expect(Rails.logger).to have_received(:error).with('引数を指定してください。')
      end
    end

    context '引数のpf_250idと一致するportalとプラットフォームの両方にデータがある選手の場合、' do
      let!(:portal_player) { create(:player) }
      let!(:portal_player_original_info) { create(:player_original_info, player: portal_player, pf_250_regist_id: pf_250id) }

      let!(:pf_player) do
        update_players_mock_response = ActiveSupport::JSON.decode(File.read("lib/platform/mock_responses/pf_250id_#{pf_250id}_player.json")).to_json
        JSON.parse(update_players_mock_response)['id_list'][0]
      end

      let(:pf_250id) { '2107070001' } # lib/platform/mock_responses/pf_250id_2107070001_player.json

      it 'playerレコードとplayer_original_infoレコードは追加しない' do
        expect { player_update_by_250id }.to change(Player, :count).by(0).and change(PlayerOriginalInfo, :count).by(0)
      end

      it 'レスポンスの選手情報とplayer, player_original_infoレコードが一致する（APIの出力に使用されるカラムのみ確認）' do
        player_update_by_250id

        expect(portal_player.reload.pf_player_id).to eq(pf_player['player_id'])
        expect(portal_player_original_info.reload.last_name_jp).to eq(pf_player['original_info']['last_name_jp'])
        expect(portal_player_original_info.reload.first_name_jp).to eq(pf_player['original_info']['first_name_jp'])
        expect(portal_player_original_info.reload.evaluation).to eq(pf_player['original_info']['evaluation'])
        expect(portal_player_original_info.reload.power).to eq(pf_player['original_info']['power'])
        expect(portal_player_original_info.reload.mental).to eq(pf_player['original_info']['mental'])
        expect(portal_player_original_info.reload.speed).to eq(pf_player['original_info']['speed'])
        expect(portal_player_original_info.reload.stamina).to eq(pf_player['original_info']['stamina'])
        expect(portal_player_original_info.reload.technique).to eq(pf_player['original_info']['technique'])
        expect(portal_player_original_info.reload.nickname).to eq(pf_player['original_info']['nickname'])
        expect(portal_player_original_info.reload.year_best).to eq(pf_player['original_info']['year_best'])
        expect(portal_player_original_info.reload.major_title).to eq(pf_player['original_info']['major_title'])
        expect(portal_player_original_info.reload.free2).to eq(pf_player['original_info']['free2'])
        expect(portal_player_original_info.reload.free3).to eq(pf_player['original_info']['free3'])
        expect(portal_player_original_info.reload.free4).to eq(pf_player['original_info']['free4'])
        expect(portal_player_original_info.reload.free5).to eq(pf_player['original_info']['free5'])
        expect(portal_player_original_info.reload.pf_250_regist_id).to eq(pf_player['original_info']['250id'])
      end
    end

    context '引数pf_250idに該当するデータがプラットフォームにはあるが、ポータルに該当するレコードが存在しない場合、' do
      let!(:pf_player) do
        update_players_mock_response = ActiveSupport::JSON.decode(File.read("lib/platform/mock_responses/pf_250id_#{pf_250id}_player.json")).to_json
        JSON.parse(update_players_mock_response)['id_list'][0]
      end

      let(:new_portal_player) { Player.find_by(pf_player_id: pf_player['player_id']) }
      let(:new_portal_player_original_info) { new_portal_player&.player_original_info }

      let(:pf_250id) { '2107070001' } # lib/platform/mock_responses/pf_250id_2107070001_player.json

      it 'playerレコードとplayer_original_infoレコードが新規追加される' do
        expect { player_update_by_250id }.to \
          change(Player, :count).by(1).and \
            change(PlayerOriginalInfo, :count).by(1)
      end

      it 'レスポンスの選手情報とplayer, player_original_infoレコードが一致する（APIの出力に使用されるカラムのみ確認）' do
        player_update_by_250id

        expect(new_portal_player.reload.pf_player_id).to eq(pf_player['player_id'])
        expect(new_portal_player_original_info.reload.last_name_jp).to eq(pf_player['original_info']['last_name_jp'])
        expect(new_portal_player_original_info.reload.first_name_jp).to eq(pf_player['original_info']['first_name_jp'])
        expect(new_portal_player_original_info.reload.evaluation).to eq(pf_player['original_info']['evaluation'])
        expect(new_portal_player_original_info.reload.power).to eq(pf_player['original_info']['power'])
        expect(new_portal_player_original_info.reload.mental).to eq(pf_player['original_info']['mental'])
        expect(new_portal_player_original_info.reload.speed).to eq(pf_player['original_info']['speed'])
        expect(new_portal_player_original_info.reload.stamina).to eq(pf_player['original_info']['stamina'])
        expect(new_portal_player_original_info.reload.technique).to eq(pf_player['original_info']['technique'])
        expect(new_portal_player_original_info.reload.nickname).to eq(pf_player['original_info']['nickname'])
        expect(new_portal_player_original_info.reload.year_best).to eq(pf_player['original_info']['year_best'])
        expect(new_portal_player_original_info.reload.major_title).to eq(pf_player['original_info']['major_title'])
        expect(new_portal_player_original_info.reload.free2).to eq(pf_player['original_info']['free2'])
        expect(new_portal_player_original_info.reload.free3).to eq(pf_player['original_info']['free3'])
        expect(new_portal_player_original_info.reload.free4).to eq(pf_player['original_info']['free4'])
        expect(new_portal_player_original_info.reload.free5).to eq(pf_player['original_info']['free5'])
        expect(new_portal_player_original_info.reload.pf_250_regist_id).to eq(pf_player['original_info']['250id'])
      end
    end

    context '引数のpf_250idに該当する選手データがプラットフォームにない場合、' do
      let(:pf_250id) { '99999' }

      it 'エラーが返る' do
        expect { player_update_by_250id }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end
  end

  describe 'class.race_details_get(year_month)' do
    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_details_get(nil) }.to raise_error(PfApiError, '引数がありません。')
      end
    end

    context 'hold_dailyのhold_dailyが0の場合' do
      it 'race_detailは作成されないこと' do
        hold_daily.update(hold_daily: 0)
        expect { PlatformSync.race_details_get(hold.first_day.strftime('%Y_%m')) }.not_to change(RaceDetail, :count)
      end
    end

    context 'race_detailがすでに登録されている場合' do
      let(:race) { create(:race, program_no: 1, hold_daily_schedule: create(:hold_daily_schedule, hold_daily: hold_daily)) }
      let!(:race_detail) { create(:race_detail, race: race) }

      it 'race_detailは新規作成されないこと' do
        expect { PlatformSync.race_details_get(hold.first_day.strftime('%Y_%m')) }.not_to change(RaceDetail, :count)
      end

      it 'race_detailが更新されること' do
        expect { PlatformSync.race_details_get(hold.first_day.strftime('%Y_%m')) }.to change { race_detail.reload.updated_at }
      end
    end

    context 'race_detailが登録されていない場合' do
      before do
        create(:race, program_no: 1, hold_daily_schedule: create(:hold_daily_schedule, hold_daily: hold_daily))
      end

      it 'race_detail他関連モデルが作成されること' do
        expect { PlatformSync.race_details_get(hold.first_day.strftime('%Y_%m')) }.to change(RaceDetail, :count).by(1).and \
          change(VoteInfo, :count).by(2).and \
            change(RacePlayer, :count).by(1).and \
              change(RacePlayerStat, :count).by(1).and \
                change(BikeInfo, :count).by(1).and \
                  change(FrontWheelInfo, :count).by(1).and \
                    change(RearWheelInfo, :count).by(1)
      end
    end
  end

  describe 'class.race_detail_get(pf_hold_id, hold_id_daily)' do # race_detailをhold_daily単位で取得して登録する
    let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily) }

    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_detail_get(nil, nil) }.to raise_error(PfApiError, '引数がありません。')
      end
    end

    context '該当する出走表がプラットフォームにない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_detail_get(1, 10) }.to raise_error(PfApiError, '出走表が取得できませんでした。')
      end
    end

    context 'race_detailがすでに登録されている場合' do
      before do
        create(:race_detail, race: race, race_status: 1)
        create(:race, program_no: 2, hold_daily_schedule: hold_daily_schedule)
        allow(Rails.logger).to receive(:error).with('raceが見つかりません。')
        allow(Rails.logger).to receive(:error).with('出走表詳細が取得できませんでした。')
        allow(Rails.logger).to receive(:error).with('出走者が見つかりません。')
      end

      let(:race) { create(:race, program_no: 1, hold_daily_schedule: hold_daily_schedule) }

      it 'race_detailが更新されること' do
        expect { PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily) }.to change { RaceDetail.find(race.race_detail.id).race_status }.from('1').to('0')
      end

      it 'PFから取得したraceが存在しない、出走表詳細と出走者をPFから取得できない場合でも、その他のraceに対する後続処理は続くこと' do
        expect { PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily) }.to change { RaceDetail.find(race.race_detail.id).race_status }.from('1').to('0')
        expect(Rails.logger).to have_received(:error).with('raceが見つかりません。')
        expect(Rails.logger).to have_received(:error).with('出走表詳細が取得できませんでした。')
        expect(Rails.logger).to have_received(:error).with('出走者が見つかりません。')
      end

      it 'race.entries_id に値が設定されること' do
        PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily)
        expect(Race.find(race.id).entries_id).not_to be_nil
      end

      it 'RaceDetail.time_zone_code に値が設定されること' do
        response = PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily)
        expect(RaceDetail.find_by(race_id: race.id).time_zone_code).to eq(response[0]['time_zone_code'])
      end
    end

    context 'race_detailが登録されていない場合' do
      before do
        create(:race, program_no: 2, hold_daily_schedule: hold_daily_schedule)
        allow(Rails.logger).to receive(:error).with('raceが見つかりません。')
        allow(Rails.logger).to receive(:error).with('出走表詳細が取得できませんでした。')
      end

      let!(:race) { create(:race, program_no: 1, hold_daily_schedule: hold_daily_schedule) }

      it 'race_detail他関連モデルが作成されること' do
        expect { PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily) }.to change(RaceDetail, :count).by(1).and \
          change(VoteInfo, :count).by(2).and \
            change(RacePlayer, :count).by(1).and \
              change(RacePlayerStat, :count).by(1).and \
                change(BikeInfo, :count).by(1).and \
                  change(FrontWheelInfo, :count).by(1).and \
                    change(RearWheelInfo, :count).by(1)
      end

      it 'race.entries_id に値が設定されること' do
        PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily)
        expect(Race.find(race.id).entries_id).not_to be_nil
      end

      it 'RaceDetail.time_zone_code に値が設定されること' do
        response = PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily)
        expect(RaceDetail.find_by(race_id: race.id).time_zone_code).to eq(response[0]['time_zone_code'])
      end

      it 'PlayerResultの値がrace_player_statに設定されること' do
        # See lib/platform/mock_responses/pf_hold_id_1_hold_id_daily_1_race_table.json
        # and lib/platform/mock_responses/entries_id_2021010222001_race_detail.json
        player_result = create(:player_result, pf_player_id: 1)
        player_result.winner_rate = rand(0..1000) / 10.0
        player_result.second_quinella_rate = rand(0..1000) / 10.0
        player_result.third_quinella_rate = rand(0..1000) / 10.0
        player_result.save!

        PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily)

        race_player_stat = RacePlayer.find_by(pf_player_id: 1).race_player_stat
        expect(race_player_stat.winner_rate).to eq player_result.winner_rate
        expect(race_player_stat.second_quinella_rate).to eq player_result.second_quinella_rate
        expect(race_player_stat.third_quinella_rate).to eq player_result.third_quinella_rate
      end

      it 'PFから取得したraceが存在しない、出走表詳細をPFから取得できない場合でも、その他のraceに対する後続処理は続くこと' do
        expect { PlatformSync.race_detail_get(hold.pf_hold_id, hold_daily.hold_id_daily) }.to change(RaceDetail, :count).by(1)
        expect(Rails.logger).to have_received(:error).with('raceが見つかりません。')
        expect(Rails.logger).to have_received(:error).with('出走表詳細が取得できませんでした。')
      end
    end
  end

  describe 'class.race_detail_upsert!(entries_id)' do # race_detailを単独で取得し更新する
    let(:race) { create(:race, program_no: 1, hold_daily_schedule: create(:hold_daily_schedule, hold_daily: hold_daily)) }

    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_detail_upsert!(nil) }.to raise_error(PfApiError, '引数または対象のレースがありません。')
      end
    end

    context '対象のraceがない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_detail_upsert!('999999') }.to raise_error(PfApiError, '引数または対象のレースがありません。')
      end
    end

    context '該当する出走表がプラットフォームにない場合' do
      it 'Errorが上がる' do
        race = create(:race, entries_id: '777777')
        expect { PlatformSync.race_detail_upsert!(race.entries_id) }.to raise_error(PfApiError, '出走表詳細が取得できませんでした。')
      end
    end

    context '対象のraceにrace_detailがない場合' do
      it 'race_detail他関連モデルが作成されること' do
        race = create(:race, entries_id: '2021010222001')
        expect { PlatformSync.race_detail_upsert!(race.entries_id) }.to change(RaceDetail, :count).by(1).and \
          change(RacePlayerStat, :count).by(1)
      end
    end

    context 'race_detail他関連モデルが更新されること場合' do
      it 'race_detail他関連モデルが更新されること' do
        race = create(:race, entries_id: '2021010222001')
        race_detail = create(:race_detail, race: race, bike_count: 10, pattern_code: '10', time_zone_code: 2, entries_id: '2021010222001')
        race_detail.vote_infos.create(vote_type: 10, vote_status: 2)
        race_player = race_detail.race_players.create(pf_player_id: 1, bike_no: 10, miss: false)
        bike_info = create(:bike_info, race_player: race_player, frame_code: 0)
        front_wheel_info = create(:front_wheel_info, bike_info: bike_info, wheel_code: 0)
        rear_wheel_info = create(:rear_wheel_info, bike_info: bike_info, wheel_code: 0)

        expect { PlatformSync.race_detail_upsert!(race_detail.entries_id) }.to change { RaceDetail.find(race_detail.id).bike_count }.from('10').to('6').and \
          change { race_detail.vote_infos.find_by(vote_type: 10).vote_status }.from(2).to(1).and \
            change { RaceDetail.find(race_detail.id).pattern_code }.from('10').to('6').and \
              change { RaceDetail.find(race_detail.id).time_zone_code }.from(2).to(1).and \
                change { RacePlayer.find(race_player.id).bike_no }.from(10).to(1).and \
                  change { BikeInfo.find(bike_info.id).frame_code }.from('0').to(nil).and \
                    change { FrontWheelInfo.find(front_wheel_info.id).wheel_code }.from('0').to(nil).and \
                      change { RearWheelInfo.find(rear_wheel_info.id).wheel_code }.from('0').to(nil)
      end
    end
  end

  describe 'class.mediated_players_upsert!(pf_hold_id, issue_type = 0)' do
    let(:hold_not_mediated) { create(:hold, pf_hold_id: 10) }
    let(:hold_not_player) { create(:hold, pf_hold_id: 20) }
    let(:success_hold) { create(:hold, pf_hold_id: 30) }
    let(:failure_hold) { create(:hold, pf_hold_id: 50) }

    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.mediated_players_upsert!(nil) }.to raise_error(PfApiError, '引数または対象の開催がありません。')
      end
    end

    context '対象のholdがない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.mediated_players_upsert!('999999') }.to raise_error(PfApiError, '引数または対象の開催がありません。')
      end
    end

    context 'あっせん選手情報が取得できない場合' do
      it 'あっせん選手情報は登録されない' do
        expect { PlatformSync.mediated_players_upsert!(hold_not_mediated.pf_hold_id) }.not_to change(MediatedPlayer, :count)
      end

      it 'result_codeが100ではない場合、Errorが上がる' do
        expect { PlatformSync.mediated_players_upsert!(failure_hold.pf_hold_id) }.to raise_error(PfApiError, 'あっせん選手情報が取得できませんでした。')
      end
    end

    context 'あっせん選手情報が取得できたが、対象の選手が見つからない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.mediated_players_upsert!(hold_not_player.pf_hold_id) }.to raise_error(PfApiError, '対象の選手が見つかりません。')
      end
    end

    context 'あっせん選手情報が対象のholdになく成功した場合' do
      it 'mediated_playerモデルが作成されること、holdとplayerが紐づくこと' do
        create(:player, pf_player_id: 10)
        expect { PlatformSync.mediated_players_upsert!(success_hold.pf_hold_id) }.to change(MediatedPlayer, :count).from(0).to(1).and change { Hold.find(success_hold.id).players.count }.from(0).to(1)
      end
    end

    context 'あっせん選手情報が対象のholdすでにあり成功した場合' do
      it 'mediated_playerモデルが更新されること' do
        player = create(:player, pf_player_id: 10)
        hold_player = create(:hold_player, player: player, hold: success_hold)
        mediated_player = create(:mediated_player, hold_player: hold_player)

        expect { PlatformSync.mediated_players_upsert!(success_hold.pf_hold_id) }.to change(MediatedPlayer, :count).by(0).and change(HoldPlayer, :count).by(0).and change { MediatedPlayer.find(mediated_player.id).repletion_code }.from('5').to('0')
      end
    end

    context 'issue_listが1件のとき' do
      # see lib/platform/mock_responses/pf_hold_id_30_mediated_player.json
      let(:hold) { create(:hold, pf_hold_id: 30) }
      let!(:player) { create(:player, pf_player_id: 10) }

      it 'LastHoldPlayerResolver.resolve が1回呼ばれること' do
        allow(LastHoldPlayerResolver).to receive(:resolve)

        PlatformSync.mediated_players_upsert!(hold.pf_hold_id)
        expect(LastHoldPlayerResolver).to have_received(:resolve).once
        expect(LastHoldPlayerResolver).to have_received(:resolve).with(hash_including(hold_id: hold.id, player_id: player.id)).once
      end
    end

    context 'issue_listが2件のとき' do
      # see lib/platform/mock_responses/pf_hold_id_40_mediated_player.json
      let(:hold) { create(:hold, pf_hold_id: 40) }
      let!(:player1) { create(:player, pf_player_id: 10) }
      let!(:player2) { create(:player, pf_player_id: 11) }

      it 'LastHoldPlayerResolver.resolve が2回呼ばれること' do
        allow(LastHoldPlayerResolver).to receive(:resolve)

        PlatformSync.mediated_players_upsert!(hold.pf_hold_id)
        expect(LastHoldPlayerResolver).to have_received(:resolve).twice
        expect(LastHoldPlayerResolver).to have_received(:resolve).with(hash_including(hold_id: hold.id, player_id: player1.id)).once
        expect(LastHoldPlayerResolver).to have_received(:resolve).with(hash_including(hold_id: hold.id, player_id: player2.id)).once
      end
    end
  end

  describe 'class.holding_word_codes_update(update_date)' do
    subject(:holding_word_codes_update) { PlatformSync.holding_word_codes_update(update_date) }

    context '引数を渡さずに実行した場合' do
      let(:update_date) { nil }

      it 'Errorが上がる' do
        expect { holding_word_codes_update }.to raise_error(PfApiError, '引数を確認してください。')
      end
    end

    context 'プラットフォームから開催マスタが取得できなかった場合' do
      let(:update_date) { 1234567 }

      it 'Errorが上がる' do
        expect { holding_word_codes_update }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end

    context 'すでにword_code.master_idが存在し、WordCodeとWordNameのカラム内容がすべて同じ場合' do
      let!(:existing_word_code) do
        create(:word_code,
               master_id: '1',
               identifier: '101',
               code: '11')
      end
      let!(:existing_word_name) do
        create(:word_name,
               word_code: existing_word_code,
               lang: 'jp',
               name: '既存の名前',
               abbreviation: '既')
      end
      let(:update_date) { '20200202' } # mock => ./lib/platform/mock_responses/update_20200202_holding_master.json

      it 'レコードの追加も変更もされないこと' do
        expect { holding_word_codes_update }.to not_change(WordCode, :count).and \
          not_change(WordName, :count).and \
            not_change { WordCode.find(existing_word_code.id).updated_at }.and \
              not_change { WordName.find(existing_word_name.id).updated_at }
      end
    end

    context 'すでにword_code.master_idが存在し、カラム内容が異なる場合' do
      let!(:existing_word_code) do
        create(:word_code,
               master_id: '1',
               identifier: '101',
               code: '11')
      end
      let!(:existing_word_name) do
        create(:word_name,
               word_code: existing_word_code,
               lang: 'jp',
               name: '既存の名前',
               abbreviation: '既')
      end
      let(:update_date) { '20200303' } # mock => ./lib/platform/mock_responses/update_20200303_holding_master.json

      it '既存のレコードが変更されること' do
        expect { holding_word_codes_update }.to not_change(WordCode, :count).and \
          not_change(WordName, :count).and \
            change { WordCode.find(existing_word_code.id).code }.from(existing_word_code.code).to('1010').and \
              change { WordCode.find(existing_word_code.id).name1 }.from(existing_word_code.name1).to('東').and \
                change { WordCode.find(existing_word_code.id).name2 }.from(existing_word_code.name2).to('東京').and \
                  change { WordCode.find(existing_word_code.id).name3 }.from(existing_word_code.name3).to('東　京').and \
                    change { WordName.find(existing_word_name.id).name }.from(existing_word_name.name).to('新しい名前').and \
                      change { WordCode.find(existing_word_code.id).updated_at }.and \
                        change { WordName.find(existing_word_name.id).updated_at }
      end
    end

    context 'word_code.master_idが存在しない場合' do
      let(:update_date) { '20200303' } # mock => ./lib/platform/mock_responses/update_20200303_holding_master.json

      it 'word_codeが作成されること' do
        expect { holding_word_codes_update }.to change(WordCode, :count).from(0).to(1).and \
          change(WordName, :count).from(0).to(1)
        expect(WordCode.find_by(master_id: '1').name1).to eq('東')
        expect(WordCode.find_by(master_id: '1').name2).to eq('東京')
        expect(WordCode.find_by(master_id: '1').name3).to eq('東　京')
      end
    end
  end

  describe 'class.time_trial_result_upsert!(pf_hold_id)' do
    let(:success_hold) { create(:hold, pf_hold_id: 100) }
    let(:not_get_hold) { create(:hold, pf_hold_id: 200) }
    let(:hold_with_not_confirmed_time_trial) { create(:hold, pf_hold_id: 300) }

    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.time_trial_result_upsert!(nil) }.to raise_error(PfApiError, 'hold_idがありません。')
      end
    end

    context '対象のholdがない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.time_trial_result_upsert!('999999') }.to raise_error(PfApiError, '対象の開催がありません。')
      end
    end

    context 'エラーコードが返ってきた場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.time_trial_result_upsert!(not_get_hold.pf_hold_id) }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end

    context 'time_trial_resultモデル関連が対象のholdになく成功した場合' do
      it 'time_trial_resultモデル他関連モデルが作成されること' do
        expect { PlatformSync.time_trial_result_upsert!(success_hold.pf_hold_id) }.to change(TimeTrialResult, :count).from(0).to(1).and change(TimeTrialPlayer, :count)
          .from(0).to(2).and change(TimeTrialBikeInfo, :count)
          .from(0).to(2).and change(TimeTrialFrontWheelInfo, :count)
          .from(0).to(2).and change(TimeTrialRearWheelInfo, :count)
          .from(0).to(2)
      end
    end

    context 'time_trial_resultモデル関連が対象のholdにすでにあり成功した場合' do
      it 'time_trial_resultモデル他関連モデルが更新されること' do
        result = create(:time_trial_result, hold: success_hold, pf_hold_id: success_hold.pf_hold_id, confirm: false)
        player = create(:time_trial_player, time_trial_result: result, pf_player_id: '6', ranking: 2)
        bike_info = create(:time_trial_bike_info, time_trial_player: player, frame_code: '111')
        front_wheel = create(:time_trial_front_wheel_info, time_trial_bike_info: bike_info, wheel_code: '111')
        rear_wheel = create(:time_trial_rear_wheel_info, time_trial_bike_info: bike_info, wheel_code: '111')
        expect { PlatformSync.time_trial_result_upsert!(success_hold.pf_hold_id) }.to change(TimeTrialResult, :count).by(0).and change(TimeTrialPlayer, :count)
          .from(1).to(2).and change(TimeTrialBikeInfo, :count)
          .from(1).to(2).and change(TimeTrialFrontWheelInfo, :count)
          .from(1).to(2).and change(TimeTrialRearWheelInfo, :count)
          .from(1).to(2)

        expect(result.reload.confirm).to be_truthy
        expect(player.reload.ranking).to eq(1)
        expect(player.reload.grade_code).to eq('5')
        expect(player.reload.repletion_code).to eq('4')
        expect(player.reload.race_code).to eq('1')
        expect(player.reload.first_race_code).to eq('C')
        expect(player.reload.entry_code).to eq('6')
        expect(player.reload.pattern_code).to eq('6')
        expect(bike_info.reload.frame_code).to eq('000')
        expect(front_wheel.reload.wheel_code).to eq('000')
        expect(rear_wheel.reload.wheel_code).to eq('000')
      end
    end

    context '速報連携時に選手を誤って登録した場合' do
      it '確定連携の場合はtime_trial_resultモデル他関連モデル削除されること' do
        result = create(:time_trial_result, hold: success_hold, pf_hold_id: success_hold.pf_hold_id, confirm: false)
        player = create(:time_trial_player, time_trial_result: result, pf_player_id: '8', ranking: 2)
        bike_info = create(:time_trial_bike_info, time_trial_player: player, frame_code: '111')
        front_wheel = create(:time_trial_front_wheel_info, time_trial_bike_info: bike_info, wheel_code: '111')
        rear_wheel = create(:time_trial_rear_wheel_info, time_trial_bike_info: bike_info, wheel_code: '111')
        expect { PlatformSync.time_trial_result_upsert!(success_hold.pf_hold_id) }.to change(TimeTrialResult, :count).by(0).and change(TimeTrialPlayer, :count)
          .from(1).to(2).and change(TimeTrialBikeInfo, :count)
          .from(1).to(2).and change(TimeTrialFrontWheelInfo, :count)
          .from(1).to(2).and change(TimeTrialRearWheelInfo, :count)
          .from(1).to(2)

        expect(TimeTrialPlayer.find_by(id: player.id)).to eq nil
        expect(TimeTrialBikeInfo.find_by(id: bike_info.id)).to eq nil
        expect(TimeTrialFrontWheelInfo.find_by(id: front_wheel.id)).to eq nil
        expect(TimeTrialRearWheelInfo.find_by(id: rear_wheel.id)).to eq nil
      end

      it '速報連携の場合はtime_trial_resultモデル他関連モデルは削除されないこと' do
        result = create(:time_trial_result, hold: hold_with_not_confirmed_time_trial, pf_hold_id: hold_with_not_confirmed_time_trial.pf_hold_id, confirm: false)
        player = create(:time_trial_player, time_trial_result: result, pf_player_id: '8', ranking: 2)
        bike_info = create(:time_trial_bike_info, time_trial_player: player, frame_code: '111')
        front_wheel = create(:time_trial_front_wheel_info, time_trial_bike_info: bike_info, wheel_code: '111')
        rear_wheel = create(:time_trial_rear_wheel_info, time_trial_bike_info: bike_info, wheel_code: '111')
        expect { PlatformSync.time_trial_result_upsert!(hold_with_not_confirmed_time_trial.pf_hold_id) }.to change(TimeTrialResult, :count).by(0).and change(TimeTrialPlayer, :count)
          .from(1).to(3).and change(TimeTrialBikeInfo, :count)
          .from(1).to(3).and change(TimeTrialFrontWheelInfo, :count)
          .from(1).to(3).and change(TimeTrialRearWheelInfo, :count)
          .from(1).to(3)

        expect(TimeTrialPlayer.find_by(id: player.id)).to eq(player)
        expect(TimeTrialBikeInfo.find_by(id: bike_info.id)).to eq(bike_info)
        expect(TimeTrialFrontWheelInfo.find_by(id: front_wheel.id)).to eq(front_wheel)
        expect(TimeTrialRearWheelInfo.find_by(id: rear_wheel.id)).to eq(rear_wheel)
      end
    end
  end

  describe 'class.race_result_get(entries_id)' do # race_resultをentries_id単位で取得して登録する
    context '引数を渡さずに実行した場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_result_get(nil) }.to raise_error(PfApiError, '引数または対象の出走表詳細がありません。')
      end
    end

    context 'entries_idが対象のrace_detailがない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_result_get(9999) }.to raise_error(PfApiError, '引数または対象の出走表詳細がありません。')
      end
    end

    context 'レース結果が取得できなかった場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_result_get(create(:race_detail).entries_id) }.to raise_error(PfApiError, 'レース結果が取得できませんでした。')
      end
    end

    context '出走表詳細が取得できなかった場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_result_get(create(:race_detail, entries_id: '2021030175004').entries_id) }.to raise_error(PfApiError, '出走表詳細が取得できませんでした。')
      end
    end

    context '出走表詳細がDBに存在しない場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.race_result_get('2021030175002') }.to raise_error(PfApiError, '引数または対象の出走表詳細がありません。')
      end
    end

    context 'レース結果が取得でき、レコードが存在しない場合' do
      it 'race_detail他関連モデルが作成されること' do
        expect { PlatformSync.race_result_get(create(:race_detail, entries_id: '2021030175002').entries_id) }
          .to change(RaceResult, :count)
          .by(1).and change(PayoffList, :count)
          .by(2).and change(RaceResultPlayer, :count)
          .by(2).and change(ResultEventCode, :count)
          .by(6)
      end

      context 'hold_player が存在する場合' do
        subject(:race_result_get) { PlatformSync.race_result_get(entries_id) }

        let(:entries_id) { '2021030175003' }

        before do
          hold_daily_schedule = create(:hold_daily_schedule, hold_daily: hold_daily)
          race = create(:race, hold_daily_schedule: hold_daily_schedule, entries_id: entries_id)
          create(:race_detail, race: race, entries_id: entries_id)
          create(:hold_player, player: player, hold: hold)
        end

        context 'rank が 1 の場合' do
          # See lib/platform/mock_responses/entries_id_2021030175002_race_result.json
          let(:player) { create(:player, pf_player_id: '23') }

          it 'hold_player_result が作成されること' do
            race_result_get
            race_result_players = RaceDetail.find_by(entries_id: entries_id).race_result.race_result_players
            race_result_player = race_result_players.find_by(pf_player_id: player.pf_player_id)
            hold_player_result = race_result_player.hold_player_result
            expect(hold_player_result).not_to eq nil
          end
        end

        context 'rank が 0 で 個人状況コードがない場合' do
          # See lib/platform/mock_responses/entries_id_2021030175003_race_result.json
          let(:player) { create(:player, pf_player_id: '22') }

          it 'hold_player_result が作成されない' do
            race_result_get
            race_result_players = RaceDetail.find_by(entries_id: entries_id).race_result.race_result_players
            race_result_player = race_result_players.find_by(pf_player_id: player.pf_player_id)
            hold_player_result = race_result_player.hold_player_result
            expect(hold_player_result).to eq nil
          end
        end

        context 'rank が 0 で 個人状況コードがある場合' do
          # See lib/platform/mock_responses/entries_id_2021030175003_race_result.json
          let(:player) { create(:player, pf_player_id: '21') }

          it 'hold_player_result が作成される' do
            race_result_get
            race_result_players = RaceDetail.find_by(entries_id: entries_id).race_result.race_result_players
            race_result_player = race_result_players.find_by(pf_player_id: player.pf_player_id)
            hold_player_result = race_result_player.hold_player_result
            expect(hold_player_result).not_to eq nil
          end
        end
      end
    end

    context 'レース結果が取得でき、レコードが存在する場合' do
      let!(:race_detail) do
        create(:race_detail, entries_id: '2021030175002')
      end
      let!(:existing_race_result) do
        create(:race_result,
               race_detail: race_detail,
               entries_id: race_detail.entries_id,
               post_time: '1000')
      end
      let!(:existing_race_result_player1) do
        create(:race_result_player,
               race_result_id: existing_race_result.id)
      end
      let!(:existing_race_result_player2) do
        create(:race_result_player,
               race_result_id: existing_race_result.id,
               home_class: true)
      end

      before do
        create(:payoff_list,
               race_detail: race_detail,
               payoff_type: 10,
               vote_type: 10,
               tip1: '3',
               payoff: 5280)
        create(:payoff_list,
               race_detail: race_detail,
               payoff_type: 10,
               vote_type: 20,
               tip1: '3',
               payoff: 1000)

        3.times do |index|
          create(:result_event_code,
                 race_result_player_id: existing_race_result_player1.id,
                 priority: index,
                 event_code: 'test')
        end
        3.times do |index|
          create(:result_event_code,
                 race_result_player_id: existing_race_result_player2.id,
                 priority: index,
                 event_code: 'test')
        end
      end

      it 'race_detailの関連モデルの数が変わらず、既存レコードが削除され、新規追加されること' do
        expect { PlatformSync.race_result_get(race_detail.entries_id) }
          .to change(RaceResult, :count)
          .by(0).and change(PayoffList, :count)
          .by(0).and change(RaceResultPlayer, :count)
          .by(0).and change(ResultEventCode, :count)
          .by(0)
        expect(RaceResult.last.post_time).to eq('1148')
        expect(PayoffList.last.payoff).to eq(1910)
        expect(RaceResultPlayer.last.home_class).to eq(false)
        expect(ResultEventCode.last.event_code).to eq('a3')
        expect(ResultEventCode.last.priority).to eq(2)
      end

      it 'race_detailと他関連モデルが更新されること' do
        race_detail.update(bike_count: '10', pattern_code: '10', race_status: '0')
        race_detail.vote_infos.create(vote_type: 10, vote_status: 2)
        race_player = race_detail.race_players.create(pf_player_id: '23', bike_no: 10, miss: false)
        bike_info = create(:bike_info, race_player: race_player, frame_code: 0)
        front_wheel_info = create(:front_wheel_info, bike_info: bike_info, wheel_code: 0)
        rear_wheel_info = create(:rear_wheel_info, bike_info: bike_info, wheel_code: 0)

        expect { PlatformSync.race_result_get(race_detail.entries_id) }.to change { RaceDetail.find(race_detail.id).bike_count }.from('10').to('6').and \
          change { race_detail.vote_infos.find_by(vote_type: 10).vote_status }.from(2).to(1).and \
            change { RaceDetail.find(race_detail.id).pattern_code }.from('10').to('6').and \
              change { RaceDetail.find(race_detail.id).race_status }.from('0').to('15').and \
                change { RacePlayer.find(race_player.id).bike_no }.from(10).to(1).and \
                  change { BikeInfo.find(bike_info.id).frame_code }.from('0').to(nil).and \
                    change { FrontWheelInfo.find(front_wheel_info.id).wheel_code }.from('0').to(nil).and \
                      change { RearWheelInfo.find(rear_wheel_info.id).wheel_code }.from('0').to(nil)
      end
    end
  end

  describe 'class.annual_schedule_update(promoter, promoter_year)' do # promoter, promoter_yearで年間スケジュールを取得して登録する
    context '引数を渡さずに実行した場合' do
      it 'promoterの引数がない場合、Errorが上がる' do
        expect { PlatformSync.annual_schedule_update(nil, '2021') }.to raise_error(PfApiError, '引数がありません。')
      end

      it 'promoter_yearの引数がない場合、Errorが上がる' do
        expect { PlatformSync.annual_schedule_update('3040', nil) }.to raise_error(PfApiError, '引数がありません。')
      end
    end

    context '年間スケジュールが取得できなかった場合' do
      it 'Errorが上がる' do
        expect { PlatformSync.annual_schedule_update('3040', '2022') }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end

    context '年間スケジュールが取得できた場合' do
      it 'annual_scheduleモデルが作成されること、activeカラムがfalseであること' do
        expect { PlatformSync.annual_schedule_update('3040', '2021') }.to change(AnnualSchedule, :count)
          .by(2)
        expect(AnnualSchedule.all.pluck(:active)).to eq([false, false])
      end
    end

    context '年間スケジュールがすでに登録されていて、差分が取得できた場合' do
      it 'annual_scheduleモデルが作成と更新されること、activeカラムが更新されないこと' do
        create(:annual_schedule, pf_id: 'a1', active: true)
        expect { PlatformSync.annual_schedule_update('3040', '2021') }.to change(AnnualSchedule, :count)
          .by(1)
        schedule = AnnualSchedule.find_by(pf_id: 'a1')
        expect(schedule.first_day).to eq('20210401'.to_date)
        expect(schedule.track_code).to eq('0001')
        expect(schedule.hold_days).to eq(2)
        expect(schedule.pre_day).to eq(true)
        expect(schedule.year_name).to eq('競輪王決定戦')
        expect(schedule.year_name_en).to eq('Keirin King')
        expect(schedule.period_before_type_cast).to eq(1)
        expect(schedule.round).to eq(5)
        expect(schedule.girl).to eq(false)
        expect(schedule.promoter_times).to eq(16)
        expect(schedule.promoter_section).to eq(2)
        expect(schedule.time_zone).to eq(11)
        expect(schedule.audience).to eq(true)
        expect(schedule.grade_code).to eq('0')
        expect(schedule.promoter_year).to eq(2021)
        expect(schedule.active).to eq(true)
      end
    end

    context 'すでに登録されている年間スケジュールが、PF側には存在しない場合' do
      it 'PF側に存在しないannual_scheduleモデルが削除されること' do
        create(:annual_schedule, pf_id: 'a3', promoter_year: '2021')
        expect { PlatformSync.annual_schedule_update('3040', '2021') }.to change { AnnualSchedule.find_by(pf_id: 'a3').present? }.from(true).to(false)
      end

      it '指定したpromoter_yearと一致しない、PF側に存在しないannual_scheduleモデルは削除されないこと' do
        create(:annual_schedule, pf_id: 'a3', promoter_year: '2020')
        PlatformSync.annual_schedule_update('3040', '2021')
        expect(AnnualSchedule.find_by(pf_id: 'a3').present?).to eq(true)
      end
    end
  end

  describe 'class.player_race_result_get(player_id, hold_id)' do # player_idとhold_idを指定して、選手レース戦績情報を取得する、player_idは必須
    subject(:player_race_result_get) { PlatformSync.player_race_result_get(player_id, hold_id) }

    let(:player) { create(:player, pf_player_id: '1') }
    let(:player_id) { player.pf_player_id }
    let(:hold_id) { '1' }

    context '引数を渡さずに実行した場合' do
      context 'player_idの引数がない場合' do
        let(:player_id) { nil }
        let(:hold_id) { '123' }

        it 'Errorが上がる' do
          expect { player_race_result_get }.to raise_error(PfApiError, '対象の選手が見つかりません。')
        end
      end

      context 'hold_idの引数がない場合でも、対象のplayerがいる場合' do
        let(:hold_id) { nil }

        it 'Errorが上がらないこと' do
          expect { player_race_result_get }.not_to raise_error
        end
      end

      context '存在しないplayer_idを渡した場合' do
        let(:player_id) { '9999' }
        let(:hold_id) { '123' }

        it 'Errorが上がる' do
          expect { player_race_result_get }.to raise_error(PfApiError, '対象の選手が見つかりません。')
        end
      end
    end

    context '選手レース戦績情報が取得できなかった場合' do
      let(:player) { create(:player, pf_player_id: '6') }
      let(:hold_id) { '6' }

      it 'Errorが上がる' do
        expect { player_race_result_get }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end

    context '選手レース戦績情報が取得できた場合' do
      it 'player_race_resultモデルが作成されること' do
        expect { player_race_result_get }.to change(PlayerRaceResult, :count).by(3)
      end

      it '取得した値でplayer_race_resultモデルが作成されていること' do
        player_race_result_get
        player_race_result = player.player_race_results.min_by(&:rank)
        expect(player_race_result.hold_id).to eq('1')
        expect(player_race_result.event_date).to eq('20221101'.to_date)
        expect(player_race_result.hold_daily).to eq(1)
        expect(player_race_result.daily_status).to eq('finished_held')
        expect(player_race_result.entries_id).to eq('1')
        expect(player_race_result.race_no).to eq(2)
        expect(player_race_result.race_status).to eq(1)
        expect(player_race_result.rank).to eq(1)
        expect(player_race_result.time).to eq('12:34.5678')
        expect(player_race_result.event_code).to eq('U')
      end
    end

    context '選手レース戦績情報が取得できて結果が空配列場合' do
      let(:player) { create(:player, pf_player_id: '2') }

      it 'エラーが上がらず、PlayerRaceResultは作成されていないこと' do
        expect { player_race_result_get }.to change(PlayerRaceResult, :count).by(0)
      end
    end

    context '対象の選手の選手レース戦績情報がすでに登録されている場合' do
      let(:player_race_results) { create_list(:player_race_result, 2, hold_id: '2', player: player) }

      context 'hold_idがnilまたは空文字の場合' do
        let(:hold_id) { [nil, ''].sample }

        it 'player_race_resultモデルが一旦、全部削除されて再度登録されること' do
          old_ids = player_race_results.pluck(:id)
          expect { player_race_result_get }.to change(PlayerRaceResult, :count).by(1)
          new_ids = Player.find(player.id).player_race_results.ids
          old_ids.map { |id| expect(new_ids).not_to include(id) }
        end
      end

      context 'hold_idが存在する場合' do
        let!(:old_player_race_result) { create(:player_race_result, hold_id: '1', player: player) }

        it 'player_race_resultモデルのhold_idが一致するデータが削除されて再度登録されること' do
          player_race_reseult_ids = player_race_results.pluck(:id)
          expect { player_race_result_get }.to change(PlayerRaceResult, :count).by(2)
          new_ids = Player.find(player.id).player_race_results.ids
          player_race_reseult_ids.map { |id| expect(new_ids).to include(id) }
          expect(new_ids).not_to include(old_player_race_result.id)
        end
      end
    end

    context 'result_codeが805の場合' do
      let(:player) { create(:player, pf_player_id: 'bbb999') }

      it 'エラーが上がらず、PlayerRaceResultは作成されていないこと' do
        expect { player_race_result_get }.to change(PlayerRaceResult, :count).by(0)
      end
    end
  end

  describe 'class.player_result_update(player_id)' do # player_idで選手戦績情報を取得して登録する
    let(:player) { create(:player, pf_player_id: 'abc123') }

    context '選手戦績情報が取得できた場合' do
      it 'PlayerResultモデルが作成されること、HoldTitleモデルも２個作成されること' do
        expect { PlatformSync.player_result_update(player.pf_player_id) }.to change(PlayerResult, :count).by(1).and change(HoldTitle, :count).by(2)
      end
    end

    context '選手戦績情報がすでに登録されていて、差分が取得できた場合' do
      it 'player_resultが更新されること,hold_titleも更新・追加されること' do
        player_result = create(:player_result, pf_player_id: 'abc123', player_id: player.id, entry_count: 10)
        hold_title = player_result.hold_titles.create(pf_hold_id: 2, period: 1, round: 1)
        expect { PlatformSync.player_result_update(player.pf_player_id) }
          .to change(PlayerResult, :count)
          .by(0)
          .and change(HoldTitle, :count)
          .by(1)
          .and change { HoldTitle.find(hold_title.id).period }
          .from(1).to(0)
          .and change { HoldTitle.find(hold_title.id).round }
          .from(1).to(0)
        result = PlayerResult.find_by(pf_player_id: 'abc123')
        expect(result.entry_count).to eq(100)
        expect(result.run_count).to eq(200)
        expect(result.consecutive_count).to eq(2)
        expect(result.first_count).to eq(5)
        expect(result.second_count).to eq(90)
        expect(result.third_count).to eq(50)
        expect(result.outside_count).to eq(55)
        expect(result.first_place_count).to eq(1)
        expect(result.second_place_count).to eq(2)
        expect(result.third_place_count).to eq(3)
        expect(result.winner_rate).to eq(10.1)
        expect(result.second_quinella_rate).to eq(20.1)
        expect(result.third_quinella_rate).to eq(15.1)
      end

      it '現在あるhold_titleがレスポンスに含まれなかった場合、そのhold_titleは削除されること' do
        player_result = create(:player_result, pf_player_id: 'abc123', player_id: player.id)
        hold_title = player_result.hold_titles.create(pf_hold_id: 1, period: 1, round: 1) # レスポンスに含まれない
        player_result.hold_titles.create(pf_hold_id: 2)
        player_result.hold_titles.create(pf_hold_id: 3)
        expect { PlatformSync.player_result_update(player.pf_player_id) }
          .to change(HoldTitle, :count).by(-1).and change { HoldTitle.find_by(id: hold_title.id).present? }.from(true).to(false)
      end

      context 'holt_listのレスポンスがnullの場合' do
        it 'playerResultは保存できていること、HoldTitleは保存されていないこと' do
          hold_list_null_player = create(:player, pf_player_id: 'abc456')
          expect { PlatformSync.player_result_update(hold_list_null_player.pf_player_id) }.to change(PlayerResult, :count).by(1).and not_change(HoldTitle, :count)
        end

        it 'すでにあるHoldTitleは削除されること' do
          hold_list_null_player = create(:player, pf_player_id: 'abc456')
          player_result = create(:player_result, pf_player_id: 'abc456', player_id: hold_list_null_player.id)
          hold_title = player_result.hold_titles.create(pf_hold_id: 2)
          expect { PlatformSync.player_result_update(hold_list_null_player.pf_player_id) }.to change { HoldTitle.find_by(id: hold_title.id).present? }.from(true).to(false)
        end
      end

      context 'エラーケース' do
        it '引数がない場合、Errorが上がる' do
          expect { PlatformSync.player_result_update(nil) }.to raise_error(PfApiError, '対象の選手が見つかりません。')
        end

        it '存在しないplayer_idを渡した場合、Errorが上がる' do
          expect { PlatformSync.player_result_update('9999') }.to raise_error(PfApiError, '対象の選手が見つかりません。')
        end

        it 'result_codeが805または100ではない場合、Errorが上がる' do
          not_result_player = create(:player, pf_player_id: 'abc789')
          expect { PlatformSync.player_result_update(not_result_player.pf_player_id) }.to raise_error(PfApiError, '取得できませんでした。')
        end

        it '戦績情報が取得できない場合、Errorが上がらないこと' do
          not_result_player = create(:player, pf_player_id: 'bbb999')
          expect { PlatformSync.player_result_update(not_result_player.pf_player_id) }.to not_change(PlayerResult, :count).and not_change(HoldTitle, :count)
        end
      end
    end
  end

  describe 'class.odds_info_get(entries_id)' do
    subject(:odds_info_get) { PlatformSync.odds_info_get(entries_id) }

    let!(:race_detail) { create(:race_detail, entries_id: '2022010100000') }

    context '引数を渡さずに実行した場合' do
      let(:entries_id) { nil }

      it 'Errorが上がる' do
        expect { odds_info_get }.to raise_error(PfApiError, '[出走ID] を入力してください')
      end
    end

    context '出走表詳細がDBに存在しない場合' do
      let(:entries_id) { 999 }

      it 'Errorが上がる' do
        expect { odds_info_get }.to raise_error(PfApiError, '出走表詳細が取得できませんでした。')
      end
    end

    context 'result_codeが100ではない場合' do
      let(:entries_id) { 999 }

      before { create(:race_detail, entries_id: entries_id) }

      it 'Errorが上がる' do
        expect { odds_info_get }.to raise_error(PfApiError, '取得できませんでした。')
      end
    end

    context '存在するentries_idを渡した場合' do
      let(:entries_id) { 2022010100000 }

      it 'odds_info, odds_list, odds_detailが作成されること' do
        expect { odds_info_get }.to change(OddsInfo, :count).by(1).and \
          change(OddsList, :count).from(0).to(2).and \
            change(OddsDetail, :count).from(0).to(3)
      end

      it '保存されたデータが正しいこと' do
        odds_info_get
        odds_info = OddsInfo.last
        odds_detail = odds_info.odds_lists.find_by(vote_type: 10).odds_details.first

        expect(odds_info.fixed).to eq(false)
        expect(odds_info.odds_time).to eq('2022-01-01 11:11:11'.in_time_zone.to_datetime)
        expect(odds_info.entries_id).to eq('2022010100000')
        expect(odds_info.odds_lists.pluck(:vote_type)).to include('win', 'two_win')
        expect(odds_info.odds_lists.find_by(vote_type: 10).odds_count).to eq(1000)
        expect(odds_detail.tip1).to eq('1')
        expect(odds_detail.tip2).to eq(nil)
        expect(odds_detail.tip3).to eq(nil)
        expect(odds_detail.odds_val).to eq(4.3)
        expect(odds_detail.odds_max_val).to eq(0)
      end

      context '同じデータがモデルに存在する場合' do
        let(:odds_info) { create(:odds_info, race_detail: race_detail, entries_id: entries_id, fixed: false, odds_time: '2022-01-01 11:11:11') }
        let(:odds_list) { create(:odds_list, odds_info: odds_info, vote_type: 10, odds_count: 1000) }
        let(:odds_list2) { create(:odds_list, odds_info: odds_info, vote_type: 30, odds_count: 2000) }

        before do
          create(:odds_detail, odds_list: odds_list, tip1: '1', tip2: nil, tip3: nil, odds_val: 4.3, odds_max_val: 0)
          create(:odds_detail, odds_list: odds_list2, tip1: '1', tip2: '2', tip3: nil, odds_val: 14.8, odds_max_val: 0)
          create(:odds_detail, odds_list: odds_list2, tip1: '1', tip2: '3', tip3: nil, odds_val: 9.9, odds_max_val: 0)
        end

        it 'odds_infoが新たに保存されないこと' do
          expect { odds_info_get }.not_to change { OddsInfo.last.id }
        end

        it 'odds_listが全消し全入れされること' do
          old_ids = odds_info.odds_lists.ids
          odds_info_get
          new_ids = odds_info.odds_lists.ids
          old_ids.map { |id| expect(new_ids).not_to include(id) }
        end

        it 'odds_detailが全消し全入れされること' do
          old_ids = odds_info.odds_lists.find_by(vote_type: 10).odds_details.ids
          odds_info_get
          new_ids = odds_info.odds_lists.find_by(vote_type: 10).odds_details.ids
          old_ids.map { |id| expect(new_ids).not_to include(id) }
        end
      end
    end
  end
end
