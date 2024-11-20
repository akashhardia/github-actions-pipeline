# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Players', :admin_logged_in, type: :request do
  describe 'GET /players' do
    subject(:players_index) { get admin_players_url(format: :json), params: params }

    let(:params) {}

    before do
      create_list(:player, 10)
    end

    it 'HTTPステータスが200であること' do
      players_index
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::PlayerSerializerの属性を持つハッシュであること' do
      players_index
      json = JSON.parse(response.body)
      json['players'].all? { |hash| expect(hash.keys).to match_array(%w[createdAt display id nameJp pfPlayerId registNum updatedAt].map { |key| key.to_s.camelize(:lower) }) }
    end

    context 'パラメータの検証' do
      before do
        Player.all.each.with_index do |player, i|
          if i == 0
            player.update!(pf_player_id: '111')
          elsif i < 3
            player.update!(pf_player_id: "111#{i}")
          elsif i < 6
            player.update!(pf_player_id: "222#{i}")
          else
            player.update!(pf_player_id: "#{i}111")
          end
        end
      end

      context 'pf_player_idがある場合' do
        let(:params) { { pf_player_id: 111 } }

        it 'pf_player_idが完全一致または前方一致しているplayersを返す' do
          players_index
          json = JSON.parse(response.body)
          pf_player_ids = json['players'].map { |player| player['pfPlayerId'] }.sort
          expect(pf_player_ids).to eq(%w[111 1111 1112])
        end
      end

      context 'pf_player_idがない場合' do
        it '全てのplayersを返す' do
          players_index
          json = JSON.parse(response.body)
          pf_player_ids = json['players'].map { |player| player['pfPlayerId'] }.sort
          expect(pf_player_ids).to eq(%w[111 1111 1112 2223 2224 2225 6111 7111 8111 9111])
        end
      end
    end
  end

  describe 'PUT /players' do
    subject(:players_update) { put(admin_players_url, params: params) }

    before do
      create(:player_original_info, pf_250_regist_id: 1)
      create(:player_original_info, pf_250_regist_id: 2)
    end

    let(:upload_success_file) { '/players/upload_success.csv' }
    let(:upload_error_file) { '/players/upload_error.csv' }
    let(:upload_shift_jis_file) { '/players/upload_shift_jis_ver.csv' }

    context 'CSVファイルが添付された時' do
      context '正常にuserテーブルのsixgram_idが記載されたCSVファイルと必須項目が送られてきた場合' do
        let(:params) do
          { file: fixture_file_upload(upload_success_file, 'text/csv') }
        end

        it 'playerのデータが更新される' do
          expect { players_update }.to change { PlayerOriginalInfo.find_by(pf_250_regist_id: 1).player.catchphrase }.from(nil).to('絶対王者').and change { PlayerOriginalInfo.find_by(pf_250_regist_id: 2).player.catchphrase }.from(nil).to('無冠の帝王')
          expect(response).to have_http_status(:ok)
        end
      end

      context 'playerテーブルに無いpf_player_idが記載されたCSVファイルが送信された場合' do
        let(:params) do
          { file: fixture_file_upload(upload_error_file, 'text/csv') }
        end

        it 'bad_requestが返る' do
          players_update
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('存在しない選手のIDが含まれています')
        end
      end

      context '文字コードがUTF-8でなく、Shift-JISのCSVをアップロードした場合' do
        let(:params) do
          { file: fixture_file_upload(upload_shift_jis_file, 'text/csv') }
        end

        it 'bad_requestが返る' do
          players_update
          body = JSON.parse(response.body)
          expect(response).to have_http_status(:bad_request)
          expect(body['detail']).to eq('アップされたCSVにエラーが有ります。※CSVの文字コードはUTF-8にしてください')
        end
      end
    end
  end

  describe 'GET /csv_export' do
    subject(:export_csv) { get admin_player_export_csv_url(format: :json) }

    context '対象ユーザーが確定している時(配布されている時)' do
      before do
        create_list(:player, 10, catchphrase: 'catchphraseだよ')
      end

      it 'playerテーブルの情報を取得できる' do
        export_csv
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(10)
      end

      it '想定の属性を持つハッシュであること' do
        export_csv
        json = JSON.parse(response.body)
        json.all? { |hash| expect(hash.keys).to match_array(%w[pfPlayerId firstNameJp lastNameJp catchphrase pf250RegistId].map { |key| key.to_s.camelize(:lower) }) }
      end

      it 'キャッチフレーズの値が "null" またはnilのとき、空文字が返ること' do
        player1 = create(:player, pf_player_id: '1000', catchphrase: 'null')
        player2 = create(:player, pf_player_id: '2000', catchphrase: nil)

        export_csv
        json = JSON.parse(response.body)
        expect(json.find { |pl| pl['pfPlayerId'] == player1.pf_player_id }['catchphrase']).to eq ''
        expect(json.find { |pl| pl['pfPlayerId'] == player2.pf_player_id }['catchphrase']).to eq ''
        expect(json[0]['catchphrase']).to eq 'catchphraseだよ'
      end
    end
  end

  describe 'GET /players/:id' do
    context 'クエリパラメータが無い場合' do
      subject(:players_detail) { get admin_player_detail_url(player_original_info.player.id) }

      let(:player_original_info) { create(:player_original_info) }

      it 'HTTPステータスが200であること' do
        players_detail
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは指定の属性を持つハッシュであること' do
        players_detail
        json = JSON.parse(response.body)

        expect_data = %w[player_class regist_day delete_day keirin_regist keirin_update keirin_delete keirin_expiration
                         middle_regist middle_update middle_delete middle_expiration name_jp name_en birthday gender_code
                         country_code area_code graduate current_rank_code next_rank_code height weight chest thigh
                         leftgrip rightgrip vital lap_200 lap_400 lap_1000 max_speed dash duration
                         last_name_jp first_name_jp last_name_en first_name_en speed stamina power technique mental
                         growth original_record popular experience evaluation nickname comment season_best year_best round_best
                         race_type major_title pist6_title free1 free2 free3 free4 free5 free6 free7 free8].map { |key| key.camelize(:lower) }
        expect(expect_data).to include_keys(json.keys)
      end
    end

    context 'クエリパラメータがある場合' do
      subject(:players_detail) { get admin_player_detail_url(player_original_info.player.id), params: { summary: true } }

      let(:player_original_info) { create(:player_original_info) }

      it 'HTTPステータスが200であること' do
        players_detail
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは指定の属性を持つハッシュであること' do
        players_detail
        json = JSON.parse(response.body)

        expect_data = %w[pfPlayerId id nameJp registNum display retiredPlayerId createdAt updatedAt]
        expect(expect_data).to include_keys(json.keys)
      end

      context '引退選手のとき' do
        let!(:retired_player) { create(:retired_player, player: player_original_info.player) }

        it '引退選手IDが返ること' do
          players_detail
          json = JSON.parse(response.body)
          expect(json['retiredPlayerId']).to eq(retired_player.id)
        end
      end

      context '引退選手ではないとき' do
        it 'nilが返ること' do
          players_detail
          json = JSON.parse(response.body)
          expect(json['retiredPlayerId']).to eq(nil)
        end
      end
    end

    context 'playerが見つからない場合' do
      it 'HTTPステータスが404であること' do
        get admin_player_detail_url(9999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /players/:id/result' do
    subject(:players_result) { get admin_player_result_url(player_result.player.id) }

    let(:player_result) { create(:player_result) }

    it 'HTTPステータスが200であること' do
      players_result
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは指定の属性を持つハッシュであること' do
      players_result
      json = JSON.parse(response.body)

      expect_data = %w[consecutive_count entry_count first_count first_place_count outside_count run_count
                       second_count second_place_count second_quinella_rate third_count third_place_count
                       third_quinella_rate winner_rate].map { |key| key.camelize(:lower) }
      expect(expect_data).to include_keys(json.keys)
    end

    context 'player_resultがない場合' do
      it 'HTTPステータスが200であること' do
        player = create(:player)
        get admin_player_result_url(player.id)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'playerが見つからない場合' do
      it 'HTTPステータスが404であること' do
        get admin_player_result_url(9999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /players/:id/race_results' do
    subject(:players_race_result) { get admin_player_race_results_url(player_race_result.player.id) }

    let(:player_race_result) { create(:player_race_result) }

    it 'HTTPステータスが200であること' do
      players_race_result
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは指定の属性を持つハッシュであること' do
      players_race_result
      json = JSON.parse(response.body)

      expect_data = %w[eventDate holdDaily raceNo rank time createdAt updatedAt]
      expect(expect_data).to include_keys(json.first.keys)
    end

    context 'race_player_resultがない場合' do
      it 'HTTPステータスが200であること' do
        player = create(:player)
        get admin_player_race_results_url(player.id)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'playerが見つからない場合' do
      it 'HTTPステータスが404であること' do
        get admin_player_race_results_url(9999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
