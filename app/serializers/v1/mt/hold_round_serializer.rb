# frozen_string_literal: true

module V1
  module Mt
    # ラウンド用シリアルライザー
    class HoldRoundSerializer < ActiveModel::Serializer
      attributes :code, :season, :hold_status, :first_day, :hold_days, :has_tt_result

      def code
        object.round
      end

      def season
        object.period
      end

      def hold_status
        object.mt_hold_status
      end

      def first_day
        object.first_day.strftime('%Y-%m-%d')
      end

      def has_tt_result # rubocop:disable Naming/PredicateName
        object.time_trial_result.present?
      end
    end
  end
end
