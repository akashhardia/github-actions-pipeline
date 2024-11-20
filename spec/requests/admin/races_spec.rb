# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Races', :admin_logged_in, type: :request do
  describe 'GET /races/:id' do
    subject(:race_show) { get admin_race_url(race.id, format: :json) }

    let(:race) { create(:race) }

    it 'HTTPステータスが200であること' do
      race_show
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::RaceShowSerializerの属性を持つハッシュであること' do
      race_show
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(::RaceShowSerializer._attributes.map { |key| key.to_s.camelize(:lower) } << 'raceDetail')
    end
  end

  describe 'GET /races/:id/race_players' do
    subject(:race_players) { get admin_race_players_url(race.id, format: :json) }

    let(:race) { create(:race) }
    let(:race_detail) { create(:race_detail, race: race) }

    context 'race_detail, race_playerが存在する場合' do
      before do
        create(:race_player, :with_player, race_detail: race_detail)
      end

      it 'HTTPステータスが200であること' do
        race_players
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::RacePlayerSerializerの属性を持つハッシュであること' do
        race_players
        json = JSON.parse(response.body)
        expect(json['racePlayers'][0].keys).to match_array(::RacePlayerSerializer._attributes.map { |key| key.to_s.camelize(:lower) } << 'bikeInfo')
      end
    end

    context 'race_detailがnullの場合' do
      before do
        race.race_detail = nil
      end

      it '{"racePlayers"=>[], "status"=>"no_race_detail"} のhashが返ってくること' do
        race_players
        json = JSON.parse(response.body)
        expect(json).to eq({ 'racePlayers' => [], 'status' => 'no_race_detail' })
      end
    end

    context 'race_detailがnot null かつ race_playerがnullの場合' do
      before do
        create(:race_detail, race: race)
      end

      it '{"racePlayers"=>[], "status"=>"no_race_player"} のhashが返ってくること' do
        race_players
        json = JSON.parse(response.body)
        expect(json).to eq({ 'racePlayers' => [], 'status' => 'no_race_player' })
      end
    end
  end

  describe 'GET /races/:id/odds_info' do
    subject(:get_odds_info) { get admin_odds_info_url(race_id, format: :json) }

    let(:odds_info) { create(:odds_info) }
    let(:race) { odds_info.race_detail.race }

    context 'レコードが存在するrace_idを指定した場合' do
      let(:race_id) { race.id }

      it 'HTTPステータスが200であること' do
        get_odds_info
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::OddsInfoSerializerの属性を持つハッシュであること' do
        get_odds_info
        json = JSON.parse(response.body)
        expect(json['oddsInfo'].keys).to match_array(::OddsInfoSerializer._attributes.map { |key| key.to_s.camelize(:lower) } << 'oddsLists')
      end
    end

    context 'レコードが存在しないrace_idを指定した場合' do
      let(:race_id) { 9999 }

      it 'not_foundエラーが返ること' do
        get_odds_info
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'race_detailがnilの場合' do
      before do
        race.race_detail = nil
      end

      let(:race_id) { race.id }

      it '{"oddsInfo"=>[], "status"=>"no_race_detail"} が返ること' do
        get_odds_info
        json = JSON.parse(response.body)
        expect(json).to eq({ 'oddsInfo' => [], 'status' => 'no_race_detail' })
      end
    end

    context 'odds_infoがnilの場合' do
      before do
        race.race_detail.odds_infos = []
      end

      let(:race_id) { race.id }

      it '{"oddsInfo"=>[], "status"=>"no_odds_info"} が返ること' do
        get_odds_info
        json = JSON.parse(response.body)
        expect(json).to eq({ 'oddsInfo' => [], 'status' => 'no_odds_info' })
      end
    end
  end

  describe 'GET /races/:id/payoff_info' do
    subject(:get_payoff_info) { get admin_payoff_info_url(race_id, format: :json) }

    let(:race_detail) { create(:race_detail) }
    let(:race) { race_detail.race }

    context 'レコードが存在するrace_idを指定した場合' do
      let(:race_id) { race.id }

      it 'HTTPステータスが200であること' do
        get_payoff_info
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::RaceDetailSerializerの属性を持つハッシュであること' do
        get_payoff_info
        json = JSON.parse(response.body)
        expect(json['payoffInfo'].keys).to match_array(::RaceDetailSerializer._attributes.map { |key| key.to_s.camelize(:lower) }.push('payoffLists', 'ranks'))
      end
    end

    context 'レコードが存在しないrace_idを指定した場合' do
      let(:race_id) { 9999 }

      it 'not_foundエラーが返ること' do
        get_payoff_info
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'race_detailがnilの場合' do
      before do
        race.race_detail = nil
      end

      let(:race_id) { race.id }

      it '{"payoffInfo"=>[], "status"=>"no_race_detail"} が返ること' do
        get_payoff_info
        json = JSON.parse(response.body)
        expect(json).to eq({ 'payoffInfo' => [], 'status' => 'no_race_detail' })
      end
    end
  end

  describe 'PUT admin/races/:id/update_free_text' do
    subject(:update_free_text) do
      put admin_update_free_text_url(race.id, format: :json), params: params
    end

    let(:race_detail) { create(:race_detail, race: race) }
    let(:race) { create(:race, free_text: 'テスト') }
    let(:params) { { freeText: 'test' } }

    context '正常ケース' do
      it 'HTTPステータスが200であること、free_textが更新されていること' do
        expect { update_free_text }.to change { race.reload.free_text }.from('テスト').to('test')
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
