# frozen_string_literal: true

shared_context 'admin_jwt_mock' do
  let(:payload) do
    {
      sub: sub,
      aud: aud,
      event_id: 'mock',
      token_use: 'id',
      auth_time: auth_time,
      iss: iss,
      "cognito:username": 'mock',
      exp: exp,
      iat: auth_time,
      email: 'mock@example.com'
    }
  end

  let(:header) { { kid: 'mock', alg: 'RS256' } }

  let(:sub) { 'mock' }
  let(:aud) { CredentialHelper.cognito[:client_id] }
  let(:iss) { "https://cognito-idp.#{CredentialHelper.cognito[:region]}.amazonaws.com/#{CredentialHelper.cognito[:user_pool_id]}" }
  let(:exp) { (Time.zone.now + 3.days).to_i }
  let(:auth_time) { Time.zone.now.to_i }

  let(:rsa_private) { OpenSSL::PKey::RSA.generate 2048 }
  let(:rsa_public) { rsa_private.public_key }
  # ダミーのJWTを作っちゃう
  let(:jwt) { JWT.encode(payload, rsa_private, 'RS256', header) }

  before do
    allow(Cognito::Service).to receive(:get_token).and_return({ succeed: true, jwt: jwt, refresh_token: 'refresh_token' })
    allow(Cognito::Certification).to receive(:generate_pub_key).and_return(rsa_public)
  end
end

shared_context 'admin_logged_in' do
  include_context 'admin_jwt_mock'

  let(:params) { { email: 'mock', password: 'mock' } }

  before do
    post admin_login_url(params)
  end
end

shared_context 'sales_jwt_mock' do
  let(:sixgram_access_token_key) { [CredentialHelper.sixgram[:secret_base16]].pack('H*') }
  let(:sixgram_access_token_iat) { Time.zone.now.to_i }
  let(:sixgram_access_token_exp) { (sixgram_access_token_iat + 10.years).to_i }
  let(:sixgram_access_token_token_secret) { SecureRandom.alphanumeric(43) }

  let(:sixgram_access_token_payload) do
    client_id = CredentialHelper.sixgram[:client_id]
    token_id = "#{sales_jwt_mock_user.sixgram_id}-#{client_id}-#{sixgram_access_token_iat}"
    {
      iss: 'https://rima.ratel.com',
      aud: client_id,
      sub: sales_jwt_mock_user.sixgram_id,
      jti: token_id,
      iat: sixgram_access_token_iat,
      exp: sixgram_access_token_exp,
      scopes: [],
      token_id: token_id,
      token_secret: sixgram_access_token_token_secret
    }
  end

  let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }
  let(:sales_jwt_mock_user) { create(:user, :with_profile, sixgram_id: sales_jwt_mock_user_sixgram_id) }
  let(:sixgram_access_token) { JWT.encode(sixgram_access_token_payload, sixgram_access_token_key) }
end

shared_context 'sales_logged_in' do
  before do
    allow(LoginRequiredUuid).to receive(:generate_uuid).and_return(random_uuid)
    get sales_users_url
    get sales_users_mixi_m_callback_url(code: sales_logged_in_user_code, state: sales_logged_in_user_state)
    sales_logged_in_user
  end

  let(:sales_logged_in_user_code) { '08012345678' }
  let(:sales_logged_in_user_state) { '123' }
  let(:random_uuid) { '123' }
  let(:sales_logged_in_user) { create(:user, :with_profile, sixgram_id: sales_logged_in_user_code) }
  let(:logged_in_user_phone_number) { sales_logged_in_user.sixgram_id }
end

RSpec.configure do |config|
  config.include_context 'admin_jwt_mock', :admin_jwt_mock
  config.include_context 'admin_logged_in', :admin_logged_in
  config.include_context 'sales_jwt_mock', :sales_jwt_mock
  config.include_context 'sales_logged_in', :sales_logged_in
end
