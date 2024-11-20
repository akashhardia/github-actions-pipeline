# frozen_string_literal: true

module V1
  module Mt
    # 選手詳細情報
    class PlayerListDetailSerializer < ApplicationSerializer
      Inputs = Struct.new(:bike_no, :player) do
        alias_method :read_attribute_for_serialization, :send
      end

      attributes :bike_no,
                 :player

      belongs_to :player, key: :player, serializer: V1::Mt::PlayerDetailSerializer
    end
  end
end
