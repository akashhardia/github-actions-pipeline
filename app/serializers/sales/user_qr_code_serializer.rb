# frozen_string_literal: true

module Sales
  # 会員QRコード表示用のシリアライザー
  class UserQrCodeSerializer < ActiveModel::Serializer
    attributes :qr_user_id
  end
end
