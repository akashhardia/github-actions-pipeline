# frozen_string_literal: true

# ログインに必須のuuid生成クラス
class LoginRequiredUuid
  # 入場識別子作成クラスメソッド
  def self.generate_uuid
    SecureRandom.uuid.delete('-')
  end
end
