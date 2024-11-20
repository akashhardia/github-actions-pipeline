# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'V1::Sixgram::Payments', type: :request do
  describe 'POST /payments' do
    subject(:post_payments) { post v1_payments_url, headers: { 'X-Webhook-Token' => token } }

    context 'Tokenが一致する場合' do
      let(:token) { CredentialHelper.sixgram_payment[:x_webhook_token] }

      it '200であること' do
        post_payments
        expect(response).to have_http_status(:ok)
      end
    end

    context 'TOKENが一致しない場合' do
      let(:token) { 'token' }

      it '401であること' do
        post_payments
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:unauthorized)
        expect(body['detail']).to eq('X-Webhook-Tokenが一致しません')
      end
    end
  end
end
