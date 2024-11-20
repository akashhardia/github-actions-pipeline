# frozen_string_literal: true

require 'rails_helper'

describe Cognito::Certification, :admin_jwt_mock do
  describe '#verify_jwt!' do
    # jwtは support/login_context.rb #admin_jwt_mock で作成
    subject(:verify_jwt!) do
      described_class.verify_jwt!(jwt)
    end

    context '検証成功' do
      it 'エラーが発生しないこと' do
        expect_sub = verify_jwt!
        expect(expect_sub).to eq(sub)
      end
    end

    context 'issが違う場合' do
      let(:iss) { 'https://example.com' }

      it 'JWT検証エラーが発生すること' do
        expect { verify_jwt! }.to raise_error(JWT::InvalidIssuerError)
      end
    end

    context 'audが違う場合' do
      let(:aud) { 'example' }

      it 'JWT検証エラーが発生すること' do
        expect { verify_jwt! }.to raise_error(JWT::InvalidAudError)
      end
    end

    context 'JWTが期限切れの場合' do
      let(:exp) { (Time.zone.now - 1.hour).to_i }

      it 'JWT検証エラーが発生すること' do
        expect { verify_jwt! }.to raise_error(JWT::ExpiredSignature)
      end
    end

    context '署名(秘密鍵・公開鍵)が異なるJWTを渡した場合' do
      let(:rsa_public) { OpenSSL::PKey::RSA.generate(2048).public_key }

      it 'JWT検証エラーが発生すること' do
        expect { verify_jwt! }.to raise_error(JWT::VerificationError)
      end
    end
  end
end
