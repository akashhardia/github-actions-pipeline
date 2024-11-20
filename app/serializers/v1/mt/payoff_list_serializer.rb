# frozen_string_literal: true

module V1
  module Mt
    # 払戻情報リスト
    class PayoffListSerializer < ActiveModel::Serializer
      attributes :payoff_type, :vote_type, :tip1, :tip2, :tip3, :payoff

      # 投票タイプは数値で返す
      def vote_type
        object.vote_type_before_type_cast
      end
    end
  end
end
