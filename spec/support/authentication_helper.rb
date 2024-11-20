# frozen_string_literal: true

module AuthenticationHelper
  def access_token
    { 'Authorization': "Bearer #{CredentialHelper.gate_250[:api_token]}" }
  end
end
