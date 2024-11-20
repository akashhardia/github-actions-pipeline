# frozen_string_literal: true

require 'rails_helper'

describe Sixgram::Certification, :sales_jwt_mock do
  describe '#verify_jwt!' do
    subject(:verify_jwt!) { described_class.verify_jwt!(sixgram_access_token) }

    context 'JWT検証OK' do
      it 'decodeされ、payloadが返されること' do
        expect(verify_jwt!.symbolize_keys).to eq(sixgram_access_token_payload)
      end
    end

    context 'JWT検証エラー' do
      let(:sixgram_access_token_exp) { (Time.zone.now - 1.day).to_i }

      it 'エラーが発生すること' do
        expect { verify_jwt! }.to raise_error(JWT::ExpiredSignature)
      end
    end
  end

  describe '#generate_client_jwt' do
    subject(:generate_client_jwt) { described_class.generate_client_jwt }

    it 'クライアントJWTが生成されること' do
      jwt = generate_client_jwt
      payload = described_class.verify_jwt!(jwt)
      expect(payload['sub']).to eq(CredentialHelper.sixgram[:client_id].to_s)
    end
  end

  describe '#generate_access_jwt' do
    subject(:generate_access_jwt) { described_class.generate_access_jwt(user_auth_token, request_method) }

    let(:user_auth_token_payload) do
      {
        token_secret: Base64.urlsafe_encode64(token_secret),
        sub: 'sub',
        token_id: 'token_id'
      }
    end
    let(:token_secret) { 'token_secret' }
    let(:user_auth_token) { JWT.encode(user_auth_token_payload, 'test') }
    let(:request_method) { 'GET&/user/identification/list' }

    it 'アクセストークンJWTが生成されること' do
      jwt = generate_access_jwt
      payload, _header = JWT.decode(jwt, token_secret)
      expect(payload['sub']).to eq(user_auth_token_payload[:sub])
    end
  end
end
