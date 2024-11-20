# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Holds', :admin_logged_in, type: :request do
  describe 'GET /holds' do
    context 'クエリパラメータが無い場合' do
      subject(:hold_index) { get admin_holds_url(format: :json) }

      before do
        create(:hold)
      end

      it 'HTTPステータスが200であること' do
        hold_index
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::HoldSerializerの属性を持つハッシュであること' do
        hold_index
        json = JSON.parse(response.body)
        arr = %w[id firstDay gradeCode holdDays holdNameEn holdNameJp holdStatus promoterCode promoterSection
                 promoterTimes purposeCode repletionCode pfHoldId trackCode createdAt updatedAt].map { |key| key.to_s.camelize(:lower) }
        json.all? { |hash| expect(hash.keys).to match_array(arr) }
      end
    end

    context 'クエリパラメータが有る場合' do
      subject(:hold_index) { get admin_holds_url + '?date=2021-01-01' }

      before do
        create_list(:hold, 9)
        create(:hold, first_day: '2021-01-01')
      end

      it 'クエリパラメータで指定されている日付以降の予定開催日(初日)が設定されている開催のみ取得できる' do
        hold_index
        json = JSON.parse(response.body)
        expect(json.size).to eq(1)
      end
    end
  end

  describe 'GET /holds/:id' do
    subject(:hold_show) { get admin_hold_url(hold.id, format: :json) }

    let(:hold) { create(:hold) }

    it 'HTTPステータスが200であること' do
      hold_show
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::HoldSerializerの属性を持つハッシュであること' do
      hold_show
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(::HoldShowSerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end
  end

  describe 'GET /holds/:id/mediated_players' do
    subject(:hold_mediated_players) { get admin_mediated_players_url(hold.id, format: :json) }

    let(:mediated_player) { create(:mediated_player) }
    let(:hold) { mediated_player.hold_player.hold }

    it 'HTTPステータスが200であること' do
      hold_mediated_players
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::MediatedPlayerSerializerの属性を持つハッシュであること' do
      hold_mediated_players
      json = JSON.parse(response.body)
      json['mediatedPlayers'].all? { |hash| expect(hash.keys).to match_array(::MediatedPlayerSerializer._attributes.map { |key| key.to_s.camelize(:lower) }) }
    end
  end

  describe 'GET /holds/:id/detail' do
    subject(:hold_detail) { get admin_hold_detail_url(hold.id, format: :json) }

    let(:hold) { create(:hold) }

    it 'HTTPステータスが200であること' do
      hold_detail
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::HoldDetailSerializerの属性を持つハッシュであること' do
      hold_detail
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(::HoldDetailSerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end
  end

  describe 'GET /holds/:id/tt_movie_yt_id' do
    subject(:tt_movie_yt_id) { get admin_tt_movie_yt_id_url(hold_id, format: :json) }

    let(:hold_id) { create(:hold).id }

    it 'HTTPステータスが200であること' do
      tt_movie_yt_id
      expect(response).to have_http_status(:ok)
    end

    it 'jsonのttMovieYtIdは想定の物であること' do
      tt_movie_yt_id
      json = JSON.parse(response.body)
      expect(json['ttMovieYtId']).to eq(Hold.find(hold_id).tt_movie_yt_id)
    end

    context 'ないIDを指定した場合はnot_foundエラーが返ること' do
      let(:hold_id) { 9999 }

      it '404が返ること' do
        tt_movie_yt_id
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT /holds/:id/tt_movie_yt_id' do
    subject(:time_trial_movie_update_url) { put admin_tt_movie_yt_id_update_url(hold.id, format: :json), params: params }

    let(:hold) { create(:hold) }
    let(:params) do
      {
        ttMovieYtId: 'https://time.trial'
      }
    end

    it 'HTTPステータスが200であること' do
      time_trial_movie_update_url
      expect(response).to have_http_status(:ok)
    end

    it 'holdのtt_movie_yt_idが更新されること' do
      before_url = hold.tt_movie_yt_id
      expect { time_trial_movie_update_url }.to change { Hold.find(hold.id).tt_movie_yt_id }.from(before_url).to(params[:ttMovieYtId])
    end
  end
end
