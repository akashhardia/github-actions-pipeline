# frozen_string_literal: true

module V1
  module Mt
    # 選手詳細情報
    class PlayerResultSerializer < ApplicationSerializer
      attributes :entry_count, :first_count, :first_place_count, :outside_count, :run_count,
                 :second_count, :second_place_count, :second_quinella_rate, :third_count,
                 :third_quinella_rate, :winner_rate
    end
  end
end
