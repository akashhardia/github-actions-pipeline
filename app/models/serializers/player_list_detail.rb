# frozen_string_literal: true

module Serializers
  # 選手リストのSerializerモデル
  class PlayerListDetail < ActiveModelSerializers::Model
    attributes :bike_no, :player
  end
end
