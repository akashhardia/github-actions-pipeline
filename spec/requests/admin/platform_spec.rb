# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Platform', :admin_logged_in, type: :request do
  describe 'PUT /holds_update' do
    subject(:holds_update) { put admin_platform_holds_update_url(format: :json), params: params }

    let(:target_hold) { create(:hold, pf_hold_id: '10') }

    context 'パラメータにyear, monthを指定した場合' do
      let(:params) { { year: 2020, month: 10 } }

      it 'HTTPステータスが200であること' do
        holds_update
        expect(response).to have_http_status(:ok)
      end
    end

    context 'レコードが存在するhold_idをパラメータに指定した場合' do
      let(:params) { { year: '', month: '', hold_id: target_hold.pf_hold_id } }

      it 'HTTPステータスが200であること' do
        holds_update
        expect(response).to have_http_status(:ok)
      end

      it '対象の開催情報が更新されること' do
        expect { holds_update }.to change { target_hold.reload.updated_at }
      end
    end

    context 'パラメータにyear, month, hold_idを指定した場合' do
      let(:params) { { year: 2021, month: 10, hold_id: target_hold.pf_hold_id } }

      it 'HTTPステータスが400であること' do
        holds_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年 & 月] または [開催ID] のどちらか一方を入力してください。')
      end
    end

    context 'パラメータにyearのみを指定した場合' do
      let(:params) { { year: 2021 } }

      it 'HTTPステータスが400であること' do
        holds_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年 & 月] の両方の指定が必須です。')
      end
    end

    context 'パラメータにmonthのみを指定した場合' do
      let(:params) { { month: 10 } }

      it 'HTTPステータスが400であること' do
        holds_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年 & 月] の両方の指定が必須です。')
      end
    end

    context 'パラメータがnil場合' do
      let(:params) { nil }

      it 'HTTPステータスが400であること' do
        holds_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年 & 月] または [開催ID] を入力してください。')
      end
    end
  end

  describe 'PUT /players_update' do
    subject(:players_update) { put admin_platform_players_update_url(format: :json), params: params }

    context 'レコードが存在するupdate_dateをパラメータに指定した場合' do
      let(:params) { { update_date: '202010' } }

      it 'HTTPステータスが200であること' do
        players_update
        expect(response).to have_http_status(:ok)
      end

      it '選手情報が追加されること' do
        expect { players_update }.to change(Player, :count)
      end
    end

    context 'レコードが存在するpf_player_idをパラメータに指定した場合' do
      let(:target_player) { create(:player, pf_player_id: '1', current_rank_code: '11') }
      let(:params) { { pf_player_id: target_player.pf_player_id } }

      it 'HTTPステータスが200であること' do
        players_update
        expect(response).to have_http_status(:ok)
      end

      it '対象の選手情報が更新されること' do
        expect { players_update }.to change { target_player.reload.updated_at }
      end
    end

    context 'パラメータにupdate_date, pf_player_idを両方とも指定した場合' do
      let(:params) { { update_date: '202010', pf_player_id: '1' } }

      it 'HTTPステータスが400であること' do
        players_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年月日] または [選手ID] のどちらか一方のみを入力してください。')
      end
    end

    context 'パラメータがnilの場合' do
      let(:params) { nil }

      it 'HTTPステータスが400であること' do
        players_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年月日] または [選手ID] を入力してください。')
      end
    end

    context 'パラメータにupdate_dateが空文字で, pf_player_idを指定した場合' do
      let(:target_player) { create(:player, pf_player_id: '1', current_rank_code: '11') }
      let(:params) { { update_date: '', pf_player_id: target_player.pf_player_id } }

      it 'HTTPステータスが200であること' do
        players_update
        expect(response).to have_http_status(:ok)
      end

      it '選手個別データを取得し、データが変更されること' do
        expect { players_update }.to change { target_player.reload.current_rank_code }.from('11').to('33')
      end
    end
  end

  describe 'PUT /race_details_update' do
    subject(:race_details_update) { put admin_platform_race_details_update_url(format: :json), params: params }

    let(:hold) { create(:hold, first_day: Time.zone.today, pf_hold_id: '1') }
    let(:hold_daily) { create(:hold_daily, hold: hold) }
    let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily) }

    before do
      create(:race, hold_daily_schedule: hold_daily_schedule, program_no: 1)
    end

    context '開催情報が存在するyear_monthをパラメータに指定した場合' do
      let(:params) { { year_month: hold.first_day.strftime('%Y_%m') } }

      it 'HTTPステータスが200であること' do
        race_details_update
        expect(response).to have_http_status(:ok)
      end

      it '出走表が追加されること' do
        expect { race_details_update }.to change(RaceDetail, :count).by(1)
      end
    end

    context 'パラメータのyear_monthの形式が不正な場合' do
      let(:params) { { year_month: '2022/04' } }

      it 'HTTPステータスが400であること' do
        race_details_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年月] は "YYYY_MM" の形式で入力してください。')
      end
    end

    context 'パラメータがnilの場合' do
      let(:params) { nil }

      it 'HTTPステータスが400であること' do
        race_details_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('年月を入力してください。')
      end
    end
  end

  describe 'PUT /holding_word_codes_update' do
    subject(:holding_word_codes_update) { put admin_platform_holding_word_codes_update_url(format: :json), params: params }

    context 'update_dateをパラメータに指定した場合' do
      let(:params) { { update_date: '20200101' } }

      it 'HTTPステータスが200であること' do
        holding_word_codes_update
        expect(response).to have_http_status(:ok)
      end

      it '開催マスタが更新されること' do
        expect { holding_word_codes_update }.to change(WordCode, :count)
      end
    end

    context 'パラメータのupdate_dateの形式が不正な場合' do
      let(:params) { { update_date: '2020/0101' } }

      it 'HTTPステータスが400であること' do
        holding_word_codes_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年月日] は"YYYYMMDD" の形式で入力してください。')
      end
    end

    context 'パラメータがnilの場合' do
      let(:params) { nil }

      it 'HTTPステータスが400であること' do
        holding_word_codes_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年月日] を入力してください。')
      end
    end
  end

  describe 'PUT /annual_schedule_update' do
    subject(:annual_schedule_update) { put admin_platform_annual_schedule_update_url(format: :json), params: params }

    context 'promoter_code, promoter_yearの両方をパラメータに指定した場合' do
      let(:params) { { promoter_code: '4160', promoter_year: '2021' } }

      it 'HTTPステータスが200であること' do
        annual_schedule_update
        expect(response).to have_http_status(:ok)
      end

      it '年間スケジュールが追加されること' do
        expect { annual_schedule_update }.to change(AnnualSchedule, :count)
      end
    end

    context 'promoter_codeのみをパラメータに指定した場合' do
      let(:params) { { promoter_code: '4160' } }

      it 'HTTPステータスが400であること' do
        annual_schedule_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('主催者コードと開催年度の両方を入力してください。')
      end
    end

    context 'promoter_yearのみをパラメータに指定した場合' do
      let(:params) { { promoter_year: '2021' } }

      it 'HTTPステータスが400であること' do
        annual_schedule_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('主催者コードと開催年度の両方を入力してください。')
      end
    end

    context 'パラメータがnilの場合' do
      let(:params) { nil }

      it 'HTTPステータスが400であること' do
        annual_schedule_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('主催者コードと開催年度の両方を入力してください。')
      end
    end
  end

  describe 'PUT /player_race_result_update' do
    subject(:player_race_result_update) { put admin_platform_player_race_result_update_url(format: :json), params: params }

    context 'player_id, hold_idを指定しない場合' do
      let!(:hold) { create(:hold, first_day: '2021/10/01') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { nil }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが400であること' do
        player_race_result_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('選手IDを入力してください。')
      end
    end

    context 'hold_idだけを指定した場合' do
      let!(:hold) { create(:hold, first_day: '2021/10/01') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { { hold_id: '1' } }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが400であること' do
        player_race_result_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('選手IDを入力してください。')
      end
    end

    context 'player_idだけ指定した場合' do
      let!(:hold) { create(:hold, first_day: '2021/11/01') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { { player_id: '1' } }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが200であること' do
        player_race_result_update
        expect(response).to have_http_status(:ok)
      end

      it '選手レース戦績が追加されること' do
        expect { player_race_result_update }.to change(PlayerRaceResult, :count)
      end
    end

    context 'player_id, hold_idの両方をパラメータに指定した場合' do
      let!(:hold) { create(:hold, id: '1', first_day: '2022/11/01') }
      let!(:player) { create(:player, id: '1', pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { { player_id: '1', hold_id: '1' } }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが200であること' do
        player_race_result_update
        expect(response).to have_http_status(:ok)
      end

      it '選手レース戦績が追加されること' do
        expect { player_race_result_update }.to change(PlayerRaceResult, :count)
      end

      it '指定した開催のみの選手レース戦績が追加されること' do
        player_race_result_update
        expect(PlayerRaceResult.all.map { |hash| hash['hold_id'] }).to match_array([hold.id.to_s, hold.id.to_s, hold.id.to_s])
      end
    end
  end

  describe 'PUT /player_result_update' do
    subject(:player_result_update) { put admin_platform_player_result_update_url(format: :json), params: params }

    context 'update_dateパラメータで指定した日が初日の開催がある場合' do
      let!(:hold) { create(:hold, first_day: '2021/10/01') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { { update_date: '20211001' } }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが200であること' do
        player_result_update
        expect(response).to have_http_status(:ok)
      end

      it '選手戦績情報が追加されること' do
        expect { player_result_update }.to change(PlayerResult, :count)
      end
    end

    context 'update_dateパラメータで指定した日の3日前までに初日の開催がない場合' do
      let!(:hold) { create(:hold, first_day: '2021/10/01') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { { update_date: '20211005' } }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが400であること' do
        player_result_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('対象の選手情報が見つかりません。')
      end

      it '選手戦績情報が追加されないこと' do
        expect { player_result_update }.to change(PlayerResult, :count).by(0)
      end
    end

    context '年月日のフォーマットに誤りがある場合' do
      let!(:hold) { create(:hold, first_day: '2021/10/01') }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { { update_date: '2020101' } }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが400であること' do
        player_result_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[年月日] は"YYYYMMDD" の形式で入力してください。')
      end
    end

    context 'パラメータがnilの場合' do
      let!(:hold) { create(:hold, first_day: Time.zone.today) }
      let!(:player) { create(:player, pf_player_id: '1') }
      let!(:hold_player) { create(:hold_player, hold: hold, player: player) }
      let(:params) { nil }

      before do
        create(:mediated_player, hold_player: hold_player)
      end

      it 'HTTPステータスが200であること' do
        player_result_update
        expect(response).to have_http_status(:ok)
      end

      it '今日から3日前までの開催の選手戦績情報が追加されること' do
        expect { player_result_update }.to change(PlayerResult, :count).by(1)
      end
    end
  end

  describe 'PUT /odds_info_update' do
    subject(:odds_info_update) { put admin_platform_odds_info_update_url(format: :json), params: params }

    before { create(:race_detail, entries_id: '2022010100000') }

    context 'entries_idをパラメータに指定しない場合' do
      let(:params) { nil }

      it 'HTTPステータスが400であること' do
        odds_info_update
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('[出走ID] を入力してください')
      end
    end

    context 'entries_idをパラメータに指定した場合' do
      let(:params) { { entries_id: 2022010100000 } }

      it 'HTTPステータスが200であること' do
        odds_info_update
        expect(response).to have_http_status(:ok)
      end

      it 'oddsが更新されること' do
        expect { odds_info_update }.to change(OddsInfo, :count).and \
          change(OddsList, :count).and \
            change(OddsDetail, :count)
      end
    end
  end
end
