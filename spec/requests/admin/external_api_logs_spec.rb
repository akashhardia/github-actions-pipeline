# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ExternalApiLogController', :admin_logged_in, type: :request do
  describe 'GET /external_api_logs' do
    subject(:external_api_log_index) { get admin_external_api_logs_url(format: :json), params: params }

    before do
      create_list(:external_api_log, 2)
    end

    it 'HTTPステータスが200であること' do
      external_api_log_index
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::ExternalApiLogSerializerの属性を持つハッシュであること' do
      external_api_log_index
      json = JSON.parse(response.body)
      json['externalApiLogs'].all? { |hash| expect(hash.keys).to match_array(::ExternalApiLogSerializer._attributes.map { |key| key.to_s.camelize(:lower) }) }
    end

    it 'IDの降順で出力されること' do
      external_api_log_index
      json = JSON.parse(response.body)
      expect(json['externalApiLogs'][0]['id']).to be > json['externalApiLogs'][1]['id']
    end

    context 'pathパラメータを指定した場合、' do
      before do
        create(:external_api_log, path: '/api/portal/race_result')
        create(:external_api_log, path: '/api/portal/race_result')
        create(:external_api_log, path: '/api/portal/race_table/seller')
      end

      let(:params) { { path: '/api/portal/race_result' } }

      it 'paramsで指定したパス名のデータのみ出力されること' do
        external_api_log_index
        json = JSON.parse(response.body)
        json['externalApiLogs'].each do |external_api_log|
          expect(external_api_log['path']).to eq('/api/portal/race_result')
        end
      end
    end
  end

  describe 'GET /external_api_log' do
    subject(:external_api_log_detail) { get admin_external_api_log_url(external_api_log.id, format: :json) }

    let(:external_api_log) { create(:external_api_log) }

    it 'HTTPステータスが200であること' do
      external_api_log_detail
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::ExternalApiLogDetailSerializerの属性を持つハッシュであること' do
      external_api_log_detail
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(::ExternalApiLogSerializer._attributes.map { |key| key.to_s.camelize(:lower) })
    end
  end
end
