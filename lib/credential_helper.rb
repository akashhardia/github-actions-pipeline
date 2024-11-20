# frozen_string_literal: true

# CredentialHelper.cognito[:client_id]のように使う
module CredentialHelper
  class << self
    delegate :pf_api, :cognito, :gate_250, :sixgram, :sixgram_payment, :face_recognition, :mixi_m, :new_system, to: :current

    def current
      @current ||= Rails.application.credentials
    end
  end
end
