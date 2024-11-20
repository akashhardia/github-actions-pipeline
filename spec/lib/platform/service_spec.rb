# frozen_string_literal: true

require 'rails_helper'

describe Platform::Service do
  let(:api_host) { 'example.com' }
  let(:request_url) { "https://#{api_host}#{api_url}?#{params.to_param}" }
  let(:request_object) { HTTParty::Request.new Net::HTTP::Get, request_url }
  let(:httparty_response) { HTTParty::Response.new(request_object, response_object, parsed_response) }

  describe '#get_calendar(year: nil, month: nil, hold_id: nil)' do
    subject(:get_calendar) { described_class.get_calendar(**params) }

    let(:api_url) { '/api/portal/calendar/seller' }
    let(:response_http_status) { 200 }
    let(:response_object) { Net::HTTPOK.new('1.1', response_http_status, 'OK') }
    let(:platform_response_body) { Platform::ServiceMock.get_calendar(**params).to_json }
    let(:parsed_response) { lambda { platform_response_body } }

    before do
      allow(response_object).to receive_messages(body: platform_response_body)
      allow(HTTParty).to receive(:get).and_return(httparty_response)
    end

    context 'PFに存在するhold_idを指定した場合' do
      let(:params) { { hold_id: '10' } }

      it 'ExternalApiLogにレコードが追加されること' do
        expect { get_calendar }.to change(ExternalApiLog, :count).from(0).to(1)
      end

      it 'ExternalApiLogにリクエスト/レスポンスパラメータが保存されること' do
        get_calendar
        api_log = ExternalApiLog.last
        expect(api_log.host).to eq(api_host)
        expect(api_log.path).to eq(api_url)
        expect(api_log.request_params).to eq(params.to_json)
        expect(api_log.response_http_status).to eq(response_http_status)
        expect(api_log.response_params).to eq(platform_response_body)
      end

      it '"ActiveRecord::ValueTooLong"が発生する場合、エラー終了せず、httparty_responseが返ること' do
        allow(ApiProvider).to receive(:api_log).and_raise(ActiveRecord::ValueTooLong)

        expect(get_calendar).to eq(httparty_response)
      end
    end

    context 'PFに存在しないhold_idを指定した場合' do
      let(:params) { { hold_id: '9999' } }

      it 'ExternalApiLogにレコードが追加されること' do
        expect { get_calendar }.to change(ExternalApiLog, :count).from(0).to(1)
      end

      it "ExternalApiLogのresponse_paramsに {'result_code' => 805} がjson形式で保存されること" do
        get_calendar
        api_log = ExternalApiLog.last
        expect(api_log.response_params).to eq({ 'result_code' => 805 }.to_json)
      end
    end
  end
end
