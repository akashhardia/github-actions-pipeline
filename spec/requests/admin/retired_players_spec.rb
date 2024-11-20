# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'RetiredPlayers', :admin_logged_in, type: :request do
  describe 'POST admin/retired_players' do
    subject(:create_retired_player) { post admin_retired_players_url, params: params }

    let(:player) { create(:player) }

    context '正常なパラメーターが送られてきた場合' do
      let(:params) { { player_id: player.id } }

      it 'レコードが登録される' do
        expect { create_retired_player }.to change(RetiredPlayer, :count).by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'レコードの値が正しいこと' do
        create_retired_player
        travel_to Time.zone.now do
          expect(RetiredPlayer.first.player_id).to eq(player.id)
          expect(RetiredPlayer.first.retired_at).to eq(Time.zone.now)
        end
      end
    end

    context 'パラメータが存在しない場合' do
      let(:params) { nil }

      it 'レコードは登録されない' do
        expect { create_retired_player }.to not_change(RetiredPlayer, :count)
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('[選手ID] を入力してください')
        expect(response).to have_http_status(:bad_request)
      end
    end

    context '指定した選手が存在しなかった場合' do
      let(:params) { { player_id: 999 } }

      it 'レコードは登録されない' do
        expect { create_retired_player }.to not_change(RetiredPlayer, :count)
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('対象の選手が見つかりません')
        expect(response).to have_http_status(:not_found)
      end
    end

    context '指定した選手が既に引退していた場合' do
      let(:params) { { player_id: player.id } }

      it 'レコードは登録されない' do
        create(:retired_player, player_id: player.id)
        expect { create_retired_player }.to not_change(RetiredPlayer, :count)
        json = JSON.parse(response.body)
        expect(json['detail']).to eq('既に引退登録済みです')
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE admin/retired_players/:id' do
    subject(:destroy_retired_player) { delete admin_retired_player_url(retired_player_id) }

    before do
      create_list(:retired_player, 2)
    end

    context 'パラメータで指定した引退選手がテーブルに存在した場合' do
      let!(:retired_player) { create(:retired_player) }
      let(:retired_player_id) { retired_player.id }

      it 'レコードが削除されること' do
        expect { destroy_retired_player }.to change(RetiredPlayer, :count).by(-1)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'パラメータで指定した引退選手がテーブルに存在しない場合' do
      let(:retired_player_id) { 999 }

      it 'レコードは削除されず、エラーが返ること' do
        expect { destroy_retired_player }.not_to change(RetiredPlayer, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
