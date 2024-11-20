# frozen_string_literal: true

module FaceRecognition
  # 顔認証アプリの認証情報呼び出し
  class Credential
    class << self
      def secret_key
        CredentialHelper.face_recognition[:secret_key]
      end

      def api_host
        CredentialHelper.face_recognition[:api_host]
      end
    end
  end
end
