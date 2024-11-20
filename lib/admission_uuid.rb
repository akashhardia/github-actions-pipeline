# frozen_string_literal: true

# 入場識別子のuuid生成クラス
class AdmissionUuid
  # 入場識別子作成クラスメソッド
  def self.generate_uuid
    SecureRandom.uuid.delete('-')
  end
end
