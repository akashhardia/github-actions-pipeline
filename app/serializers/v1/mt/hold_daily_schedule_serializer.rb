# frozen_string_literal: true

module V1
  module Mt
    # 興行情報シリアルライザー
    class HoldDailyScheduleSerializer < ActiveModel::Serializer
      attributes :id, :hold_schedule_status, :event_date, :promoter_year, :season, :round_code, :day_night, :event_time, :event_code

      def promoter_year
        object.hold_daily.hold.promoter_year
      end

      def season
        object.hold_daily.hold.period
      end

      def round_code
        object.hold_daily.hold.round
      end

      # 開催日区分は数値で返す
      def day_night
        object.daily_no_before_type_cast
      end

      def event_time
        object.opening_display
      end

      def event_code
        # event_code == "W", "X", "Y"（順位決定戦C,D,E）の場合はすべて"T"（順位決定戦）に変換
        return 'T' if %w[W X Y].include? object.high_priority_event_code

        object.high_priority_event_code
      end

      # 平常：１
      # 中止：２
      def hold_schedule_status
        daily_canceled_status = %w[canceled_in_inspection canceled_before_inspection discontinuation canceled_full_return canceled_takeover]

        daily_canceled_status.include?(object.hold_daily.daily_status) || (object.hold_daily.hold.finished_held? && object.hold_daily.race_details.count.zero?) ? 2 : 1
      end
    end
  end
end
